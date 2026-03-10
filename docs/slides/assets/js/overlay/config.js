(() => {
  const ns = window.DeckOverlay || (window.DeckOverlay = {});

  const get = (value, fallback = "") => value ?? fallback;
  const normalizeCssLength = (value, fallback = "0px") => {
    const raw = String(get(value, "")).trim();
    const candidate = raw !== "" ? raw : String(get(fallback, "0px")).trim();
    if (!candidate) {
      return "0px";
    }

    if (/^[+-]?(?:\d+|\d*\.\d+)$/.test(candidate)) {
      return `${candidate}px`;
    }

    return candidate;
  };

  const parseScript = () => {
    const script = document.getElementById("overlay-config");
    if (!script) {
      return null;
    }

    try {
      return JSON.parse(script.textContent || "{}");
    } catch (error) {
      console.error("Failed to parse overlay config", error);
      return null;
    }
  };

  const createConfig = (rawCfg) => ({
    overlay: {
      text: String(get(rawCfg.overlay?.text, "")).replace(/\r\n/g, "\n").replace(/^\n+|\n+$/g, ""),
      position: {
        default: {
          x: normalizeCssLength(rawCfg.overlay?.position?.default?.x, "40"),
          y: normalizeCssLength(rawCfg.overlay?.position?.default?.y, "30")
        },
        title: {
          x: normalizeCssLength(rawCfg.overlay?.position?.title?.x, "70"),
          y: normalizeCssLength(rawCfg.overlay?.position?.title?.y, "90")
        }
      },
      style: {
        fontSize: get(rawCfg.overlay?.style?.fontSize, "0.7em"),
        opacity: get(rawCfg.overlay?.style?.opacity, "0.85"),
        lineHeight: get(rawCfg.overlay?.style?.lineHeight, "1.3"),
        textAlign: get(rawCfg.overlay?.style?.textAlign, "center"),
        anchorX: get(rawCfg.overlay?.style?.anchorX, "center"),
        titleColor: get(rawCfg.overlay?.style?.titleColor, "white")
      }
    },
    pageNumber: {
      position: {
        x: normalizeCssLength(rawCfg.pageNumber?.position?.x, "1188"),
        y: normalizeCssLength(rawCfg.pageNumber?.position?.y, "56")
      },
      style: {
        currentFontSize: get(rawCfg.pageNumber?.style?.currentFontSize, "2.4em"),
        totalFontSize: get(rawCfg.pageNumber?.style?.totalFontSize, "0.9em"),
        color: get(rawCfg.pageNumber?.style?.color, "#4f4f4f"),
        opacity: get(rawCfg.pageNumber?.style?.opacity, "1"),
        lineGap: get(rawCfg.pageNumber?.style?.lineGap, "0.2em"),
        textAlign: get(rawCfg.pageNumber?.style?.textAlign, "center"),
        anchorX: get(rawCfg.pageNumber?.style?.anchorX, "center")
      }
    },
    titleSlide: {
      title: {
        x: normalizeCssLength(rawCfg.titleSlide?.title?.x, "96"),
        y: normalizeCssLength(rawCfg.titleSlide?.title?.y, "226"),
        fontSize: get(rawCfg.titleSlide?.title?.fontSize, "1.55em"),
        color: get(rawCfg.titleSlide?.title?.color, "#208177")
      },
      subtitle: {
        x: normalizeCssLength(rawCfg.titleSlide?.subtitle?.x, "96"),
        y: normalizeCssLength(rawCfg.titleSlide?.subtitle?.y, "320"),
        fontSize: get(rawCfg.titleSlide?.subtitle?.fontSize, "0.96em"),
        color: get(rawCfg.titleSlide?.subtitle?.color, "#333333")
      },
      author: {
        x: normalizeCssLength(rawCfg.titleSlide?.author?.x, "96"),
        y: normalizeCssLength(rawCfg.titleSlide?.author?.y, "380"),
        fontSize: get(rawCfg.titleSlide?.author?.fontSize, "0.88em"),
        color: get(rawCfg.titleSlide?.author?.color, "#333333")
      },
      affiliation: {
        x: normalizeCssLength(rawCfg.titleSlide?.affiliation?.x, "96"),
        y: normalizeCssLength(rawCfg.titleSlide?.affiliation?.y, "412"),
        fontSize: get(rawCfg.titleSlide?.affiliation?.fontSize, "0.82em"),
        color: get(rawCfg.titleSlide?.affiliation?.color, "#333333")
      }
    },
    docMeta: {
      authorText: String(get(rawCfg.docMeta?.authorText, "")),
      affiliationText: String(get(rawCfg.docMeta?.affiliationText, ""))
    },
    eyecatch: {
      title: {
        x: normalizeCssLength(rawCfg.eyecatch?.title?.x, "165"),
        y: normalizeCssLength(rawCfg.eyecatch?.title?.y, "330"),
        maxWidth: normalizeCssLength(rawCfg.eyecatch?.title?.maxWidth, "900"),
        fontSize: get(rawCfg.eyecatch?.title?.fontSize, "2.4em"),
        color: get(rawCfg.eyecatch?.title?.color, "#333333"),
        fontWeight: get(rawCfg.eyecatch?.title?.fontWeight, "700"),
        lineHeight: get(rawCfg.eyecatch?.title?.lineHeight, "1.1"),
        letterSpacing: get(rawCfg.eyecatch?.title?.letterSpacing, "0"),
        anchorX: get(rawCfg.eyecatch?.title?.anchorX, "left")
      }
    }
  });

  ns.config = {
    parseScript,
    createConfig,
  };
})();
