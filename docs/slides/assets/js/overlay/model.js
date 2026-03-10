(() => {
  const ns = window.DeckOverlay || (window.DeckOverlay = {});

  const isTitleSlide = (slide) => Boolean(
    slide?.id === "title-slide" ||
    slide?.classList?.contains("quarto-title-block") ||
    slide?.classList?.contains("title-slide")
  );

  const isEyecatchSlide = (slide) => Boolean(slide?.classList?.contains("deck-eyecatch-slide"));

  const getLeafSlides = () => {
    const revealSlides = window.Reveal?.getSlides?.();
    if (Array.isArray(revealSlides) && revealSlides.length > 0) {
      return revealSlides.filter((slide) => !slide.classList?.contains("stack"));
    }
    return Array.from(document.querySelectorAll(".reveal .slides section:not(.stack)"));
  };

  const isHiddenByAttribute = (element, slideRoot) => {
    const hiddenAncestor = element?.closest?.("[hidden], [aria-hidden='true']");
    if (!hiddenAncestor) return false;
    if (slideRoot && hiddenAncestor === slideRoot) return false;
    return true;
  };

  const isIgnoredSubtree = (element, slideRoot) => Boolean(
    element?.closest?.(".notes, script, style, template") || isHiddenByAttribute(element, slideRoot)
  );

  const isCandidateElement = (element, slideRoot) => {
    if (!element) return false;
    if (isIgnoredSubtree(element, slideRoot)) return false;
    return true;
  };

  const hasVisibleContent = (slide) => {
    if (!slide) return false;

    const walker = document.createTreeWalker(
      slide,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode(node) {
          const parent = node.parentElement;
          if (!parent) return NodeFilter.FILTER_REJECT;
          if (isIgnoredSubtree(parent, slide)) {
            return NodeFilter.FILTER_REJECT;
          }
          return NodeFilter.FILTER_ACCEPT;
        }
      }
    );

    const textParts = [];
    while (walker.nextNode()) {
      const text = String(walker.currentNode.nodeValue || "").replace(/\s+/g, " ").trim();
      if (!text) continue;
      textParts.push(text);
      if (textParts.length >= 256) break;
    }

    const text = textParts.join(" ").replace(/\s+/g, " ").trim();
    if (text) return true;

    const candidates = slide.querySelectorAll(
      "img, svg, video, canvas, iframe, pre, code, table, ul, ol, p, h1, h2, h3, h4, h5, h6, .columns"
    );
    for (const element of candidates) {
      if (isCandidateElement(element, slide)) {
        return true;
      }
    }

    return false;
  };

  const sameSlideList = (a, b) => {
    if (!Array.isArray(a) || !Array.isArray(b)) return false;
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i += 1) {
      if (a[i] !== b[i]) return false;
    }
    return true;
  };

  const buildSlideModel = (leafSlides) => {
    const bodySlides = [];
    const countedSlides = [];
    let titleSlide = null;

    for (const slide of leafSlides) {
      const isTitle = isTitleSlide(slide);
      if (isTitle && !titleSlide) {
        titleSlide = slide;
        continue;
      }

      if (!hasVisibleContent(slide)) continue;

      countedSlides.push(slide);
      if (!isTitle && !isEyecatchSlide(slide)) {
        bodySlides.push(slide);
      }
    }

    const countedWithTitle = titleSlide ? [titleSlide, ...countedSlides] : countedSlides;
    const countedIndexMap = new WeakMap();
    countedWithTitle.forEach((slide, index) => {
      countedIndexMap.set(slide, index);
    });

    return {
      leafSlides,
      bodySlides,
      bodySlideSet: new Set(bodySlides),
      countedIndexMap,
      totalCount: countedWithTitle.length,
      leafCount: leafSlides.length
    };
  };

  const createStore = () => {
    let cache = null;

    const getSlideModel = (forceRebuild = false) => {
      const leafSlides = getLeafSlides();
      if (!forceRebuild && cache && sameSlideList(cache.leafSlides, leafSlides)) {
        cache.leafSlides = leafSlides;
        return cache;
      }

      cache = buildSlideModel(leafSlides);
      return cache;
    };

    return {
      getSlideModel,
      invalidate: () => {
        cache = null;
      }
    };
  };

  ns.model = {
    isTitleSlide,
    isEyecatchSlide,
    createStore,
  };
})();
