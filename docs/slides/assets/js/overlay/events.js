(() => {
  const ns = window.DeckOverlay || (window.DeckOverlay = {});

  const bind = (renderer) => {
    const renderAll = (options = {}) => {
      if (typeof renderer.rerenderAll === "function") {
        renderer.rerenderAll(options);
        return;
      }
      renderer.rerender(options);
    };

    const renderSlide = (slide, options = {}) => {
      if (typeof renderer.rerenderSlide === "function") {
        renderer.rerenderSlide(slide, options);
        return;
      }
      renderAll(options);
    };

    let resizeRafId = null;
    let resizeQueuedOptions = null;
    const scheduleResizeRender = (options = {}) => {
      resizeQueuedOptions = { ...(resizeQueuedOptions || {}), ...options };
      if (resizeRafId !== null) return;
      resizeRafId = window.requestAnimationFrame(() => {
        const queued = resizeQueuedOptions || {};
        resizeQueuedOptions = null;
        resizeRafId = null;
        renderAll(queued);
      });
    };

    if (window.Reveal?.on) {
      window.Reveal.on("ready", () => {
        renderAll({
          rebuildModel: true,
          updateStaticLayout: true,
          updateAnnotations: true,
        });
      });
      window.Reveal.on("slidechanged", (event) => {
        renderSlide(event?.currentSlide, {
          updateAnnotations: true,
        });
      });
      window.Reveal.on("resize", () => {
        scheduleResizeRender({
          updateAnnotations: true,
          updateStaticLayout: true,
        });
      });
    }

    window.addEventListener("beforeprint", () => {
      renderAll({
        rebuildModel: true,
        updateStaticLayout: true,
        updateAnnotations: true,
      });
    });

    try {
      const media = window.matchMedia("print");
      if (media?.addEventListener) {
        media.addEventListener("change", () => {
          renderAll({
            rebuildModel: true,
            updateStaticLayout: true,
            updateAnnotations: true,
          });
        });
      } else if (media?.addListener) {
        media.addListener(() => {
          renderAll({
            rebuildModel: true,
            updateStaticLayout: true,
            updateAnnotations: true,
          });
        });
      }
    } catch (_) {
    }

    setTimeout(() => {
      renderAll({
        rebuildModel: true,
        updateStaticLayout: true,
        updateAnnotations: true,
      });
    }, 0);
    setTimeout(() => {
      renderSlide(window.Reveal?.getCurrentSlide?.(), {
        updateAnnotations: true,
      });
    }, 250);
  };

  ns.events = {
    bind,
  };
})();
