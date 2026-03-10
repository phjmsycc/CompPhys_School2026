(() => {
  const ns = window.DeckOverlay || (window.DeckOverlay = {});

  const initOverlay = () => {
    const slidesRoot = document.querySelector(".reveal .slides");
    if (!slidesRoot) return;

    if (slidesRoot.dataset.deckOverlayInit === "1") return;
    slidesRoot.dataset.deckOverlayInit = "1";

    const rawCfg = ns.config.parseScript();
    if (!rawCfg) return;

    const cfg = ns.config.createConfig(rawCfg);
    const modelStore = ns.model.createStore();
    const renderer = ns.render.createRenderer(cfg, modelStore);

    renderer.rerenderAll({
      rebuildModel: true,
      updateStaticLayout: true,
      updateAnnotations: true,
    });
    ns.events.bind(renderer);
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initOverlay, { once: true });
  } else {
    initOverlay();
  }
})();
