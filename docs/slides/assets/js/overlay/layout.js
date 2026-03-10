(() => {
  const ns = window.DeckOverlay || (window.DeckOverlay = {});

  const anchorMap = {
    left: "translateX(0)",
    center: "translateX(-50%)",
    right: "translateX(-100%)"
  };

  const applyAbsoluteTextLayout = (el, layout, options = {}) => {
    if (!el) return;

    const anchorX = options.anchorX ?? "left";
    const textAlign = options.textAlign ?? (anchorX === "right" ? "right" : anchorX === "center" ? "center" : "left");
    const transformX = anchorX === "right"
      ? "translateX(-100%)"
      : anchorX === "center"
        ? "translateX(-50%)"
        : "none";

    el.style.position = "absolute";
    el.style.inset = "auto";
    el.style.left = layout.x;
    el.style.top = layout.y;
    el.style.right = "auto";
    el.style.bottom = "auto";
    el.style.margin = "0";
    el.style.padding = "0";
    el.style.width = "max-content";
    el.style.maxWidth = "none";
    el.style.height = "auto";
    el.style.transform = transformX;
    el.style.transformOrigin = `top ${anchorX}`;
    el.style.float = "none";
    el.style.display = "block";
    el.style.fontSize = layout.fontSize;
    el.style.color = layout.color;
    el.style.whiteSpace = "pre-line";
    el.style.writingMode = "horizontal-tb";
    el.style.textOrientation = "mixed";
    el.style.direction = "ltr";
    el.style.textAlign = textAlign;
    el.style.lineHeight = "1.2";
  };

  const normalizeText = (value) => (value ?? "")
    .replace(/\r\n/g, "\n")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();

  const getDisplayText = (nodes) => {
    const parts = [];
    const seenText = new Set();

    nodes.forEach((node) => {
      if (!node) return;
      const text = normalizeText(node.innerText ?? node.textContent ?? "");
      if (!text || seenText.has(text)) return;
      seenText.add(text);
      parts.push(text);
    });

    return parts.join("\n").replace(/\n{3,}/g, "\n\n").trim();
  };

  const toPixels = (value) => {
    if (!value) return 0;
    const raw = String(value).trim();
    if (!raw) return 0;
    if (raw.endsWith("px")) return parseFloat(raw) || 0;
    if (/^[+-]?\d+(?:\.\d+)?$/.test(raw)) return parseFloat(raw) || 0;

    const probe = document.createElement("div");
    probe.style.position = "absolute";
    probe.style.visibility = "hidden";
    probe.style.height = raw;
    document.body.appendChild(probe);
    const pixels = probe.getBoundingClientRect().height || 0;
    probe.remove();

    return pixels;
  };

  const getAnnotationBlocks = (slideEl) => {
    if (!slideEl) return [];
    return [...slideEl.querySelectorAll(":scope > aside:not(.notes), :scope > div.aside")];
  };

  const updateBodyAnnotationsForSlide = (slideEl) => {
    if (!slideEl || !slideEl.classList?.contains("deck-body-slide")) return;
    const annotations = getAnnotationBlocks(slideEl);
    if (!annotations.length) {
      slideEl.style.setProperty("--slide-annotations-height", "0px");
      return;
    }

    const reserveGap = toPixels(
      getComputedStyle(document.documentElement).getPropertyValue("--body-annotations-reserve-gap")
    );
    const totalHeight = annotations.reduce((sum, el) => sum + el.getBoundingClientRect().height, 0);
    slideEl.style.setProperty("--slide-annotations-height", `${Math.ceil(totalHeight + reserveGap)}px`);
  };

  const updateBodyAnnotations = (slides) => {
    const targets = Array.isArray(slides)
      ? slides
      : [...document.querySelectorAll(".reveal section.deck-body-slide")];

    targets.forEach((slideEl) => {
      updateBodyAnnotationsForSlide(slideEl);
    });
  };

  ns.layout = {
    anchorMap,
    applyAbsoluteTextLayout,
    getDisplayText,
    updateBodyAnnotationsForSlide,
    updateBodyAnnotations,
  };
})();
