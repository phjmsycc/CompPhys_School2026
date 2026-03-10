(() => {
  const ns = window.DeckOverlay || (window.DeckOverlay = {});

  const ensureOverlayLayer = (slide) => {
    if (!slide) return null;
    let layer = slide.querySelector(":scope > .deck-overlay-layer");
    if (!layer) {
      layer = document.createElement("div");
      layer.className = "deck-overlay-layer";
      slide.appendChild(layer);
    }
    return layer;
  };

  const createRenderer = (cfg, modelStore) => {
    const { model, layout } = ns;

    const applyTitleLayout = () => {
      const slide = document.getElementById("title-slide");
      if (!slide) return;

      const titleEl = slide.querySelector("h1.title, .title > h1, .quarto-title-block .title");
      const subtitleEl = slide.querySelector("p.subtitle, .subtitle > p, .quarto-title-block .subtitle");

      const authorContainer = slide.querySelector(".quarto-title-authors");
      const authorNameElements = Array.from(slide.querySelectorAll(".quarto-title-author-name"));
      const affiliationContainer = slide.querySelector(".quarto-title-affiliations");
      const affiliationElements = Array.from(slide.querySelectorAll(".quarto-title-affiliation"));

      if (titleEl) layout.applyAbsoluteTextLayout(titleEl, cfg.titleSlide.title);
      if (subtitleEl) layout.applyAbsoluteTextLayout(subtitleEl, cfg.titleSlide.subtitle);

      const fallbackAuthor = String(cfg.docMeta?.authorText ?? "").trim();
      const fallbackAffiliation = String(cfg.docMeta?.affiliationText ?? "").trim();

      const authorText = layout.getDisplayText(authorNameElements) || fallbackAuthor;
      const affiliationText = layout.getDisplayText(affiliationElements) || fallbackAffiliation;

      const createTitleMetaOverlay = (className, text, layoutCfg) => {
        if (!text) return null;
        slide.querySelectorAll(`.${className}`).forEach((node) => node.remove());
        const el = document.createElement("div");
        el.className = className;
        el.textContent = text;
        layout.applyAbsoluteTextLayout(el, layoutCfg, { anchorX: "right", textAlign: "right" });
        slide.appendChild(el);
        return el;
      };

      const hasAuthor = Boolean(authorText);
      const hasAffiliation = Boolean(affiliationText);

      if (hasAuthor) createTitleMetaOverlay("title-slide-author-overlay", authorText, cfg.titleSlide.author);
      if (hasAffiliation) createTitleMetaOverlay("title-slide-affiliation-overlay", affiliationText, cfg.titleSlide.affiliation);

      if (hasAuthor) {
        if (authorContainer) authorContainer.style.display = "none";
        authorNameElements.forEach((el) => {
          el.style.display = "none";
        });
      }

      if (hasAffiliation) {
        if (affiliationContainer) affiliationContainer.style.display = "none";
        affiliationElements.forEach((el) => {
          el.style.display = "none";
        });
      }
    };

    const applyEyecatchSlides = () => {
      const title = cfg.eyecatch.title;
      const anchorX = String(title.anchorX ?? "left");
      const transform = layout.anchorMap[anchorX] || layout.anchorMap.left;

      document.querySelectorAll(".reveal .slides section.deck-eyecatch-slide").forEach((section) => {
        const heading = section.querySelector(":scope > h2, :scope > h1");
        if (!heading) return;

        heading.style.left = title.x;
        heading.style.top = title.y;
        heading.style.maxWidth = title.maxWidth;
        heading.style.transform = transform;
        heading.style.fontSize = title.fontSize;
        heading.style.color = title.color;
        heading.style.fontWeight = title.fontWeight;
        heading.style.lineHeight = title.lineHeight;
        heading.style.letterSpacing = title.letterSpacing;
        heading.style.textAlign = anchorX === "right" ? "right" : anchorX === "center" ? "center" : "left";
      });
    };

    const ensureFixedText = (slide) => {
      if (!cfg.overlay.text) return null;

      const layer = ensureOverlayLayer(slide);
      if (!layer) return null;

      let el = layer.querySelector(":scope > .slide-fixed-text");
      if (!el) {
        el = document.createElement("div");
        el.className = "slide-fixed-text";
        layer.appendChild(el);
      }

      el.textContent = cfg.overlay.text;
      el.style.fontSize = cfg.overlay.style.fontSize;
      el.style.opacity = cfg.overlay.style.opacity;
      el.style.lineHeight = cfg.overlay.style.lineHeight;
      el.style.textAlign = cfg.overlay.style.textAlign;
      el.style.transform = layout.anchorMap[cfg.overlay.style.anchorX] ?? layout.anchorMap.center;

      if (model.isEyecatchSlide(slide)) {
        el.style.display = "none";
        return el;
      }

      const pos = model.isTitleSlide(slide) ? cfg.overlay.position.title : cfg.overlay.position.default;
      el.style.display = "block";
      el.style.left = pos.x;
      el.style.top = pos.y;
      el.style.color = model.isTitleSlide(slide) ? cfg.overlay.style.titleColor : "";

      return el;
    };

    const ensurePageCounter = (slide, idx, totalCount, show) => {
      const layer = ensureOverlayLayer(slide);
      if (!layer) return null;

      let counter = layer.querySelector(":scope > .slide-page-counter");
      if (!counter) {
        counter = document.createElement("div");
        counter.className = "slide-page-counter";

        const currentEl = document.createElement("span");
        currentEl.className = "slide-page-counter-current";
        currentEl.style.lineHeight = "1";
        counter.appendChild(currentEl);

        const totalEl = document.createElement("span");
        totalEl.className = "slide-page-counter-total";
        totalEl.style.lineHeight = "1";
        counter.appendChild(totalEl);

        layer.appendChild(counter);
      }

      counter.style.color = cfg.pageNumber.style.color;
      counter.style.opacity = cfg.pageNumber.style.opacity;
      counter.style.textAlign = cfg.pageNumber.style.textAlign;
      counter.style.left = cfg.pageNumber.position.x;
      counter.style.top = cfg.pageNumber.position.y;
      counter.style.transform = layout.anchorMap[cfg.pageNumber.style.anchorX] ?? layout.anchorMap.center;

      const currentEl = counter.querySelector(":scope > .slide-page-counter-current");
      const totalEl = counter.querySelector(":scope > .slide-page-counter-total");

      if (currentEl) currentEl.style.fontSize = cfg.pageNumber.style.currentFontSize;
      if (totalEl) {
        totalEl.style.fontSize = cfg.pageNumber.style.totalFontSize;
        totalEl.style.marginTop = cfg.pageNumber.style.lineGap;
      }

      if (!show || idx < 0 || totalCount <= 0) {
        counter.style.display = "none";
        return counter;
      }

      if (currentEl) currentEl.textContent = `${idx + 1}`;
      if (totalEl) totalEl.textContent = `${totalCount}`;
      counter.style.display = "flex";
      return counter;
    };

    const renderSlideOverlays = (slide, modelState) => {
      if (!slide || !modelState) return;

      ensureFixedText(slide);
      const idx = modelState.countedIndexMap.get(slide);
      const showCounter = modelState.bodySlideSet.has(slide);
      ensurePageCounter(slide, Number.isInteger(idx) ? idx : -1, modelState.totalCount, showCounter);
    };

    const rerenderAll = (options = {}) => {
      const modelState = modelStore.getSlideModel(Boolean(options.rebuildModel));

      if (options.updateStaticLayout !== false) {
        applyTitleLayout();
        applyEyecatchSlides();
      }

      if (options.updateAnnotations !== false) {
        layout.updateBodyAnnotations(modelState.bodySlides);
      }

      modelState.leafSlides.forEach((slide) => {
        renderSlideOverlays(slide, modelState);
      });
    };

    const rerenderSlide = (slide, options = {}) => {
      const modelState = modelStore.getSlideModel(Boolean(options.rebuildModel));
      const targetSlide = slide || window.Reveal?.getCurrentSlide?.() || modelState.leafSlides[0];
      if (!targetSlide) return;

      if (options.updateStaticLayout) {
        applyTitleLayout();
        applyEyecatchSlides();
      } else if (model.isTitleSlide(targetSlide)) {
        applyTitleLayout();
      }

      if (options.updateAnnotations && modelState.bodySlideSet.has(targetSlide)) {
        layout.updateBodyAnnotationsForSlide(targetSlide);
      }

      renderSlideOverlays(targetSlide, modelState);
    };

    const rerender = (options = {}) => {
      rerenderAll(options);
    };

    return {
      rerender,
      rerenderAll,
      rerenderSlide,
    };
  };

  ns.render = {
    createRenderer,
  };
})();
