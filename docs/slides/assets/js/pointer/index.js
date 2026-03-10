(() => {
  const POINTER_ID = "deck-laser-pointer";
  const REVEAL_SELECTOR = ".reveal";

  const isEditableTarget = (target) => {
    if (!(target instanceof Element)) {
      return false;
    }
    if (target.closest("input, textarea, select")) {
      return true;
    }
    let node = target;
    while (node instanceof Element) {
      if (node.isContentEditable) {
        return true;
      }
      node = node.parentElement;
    }
    return false;
  };

  const createPointer = () => {
    const element = document.createElement("div");
    element.id = POINTER_ID;
    element.setAttribute("aria-hidden", "true");
    document.body.appendChild(element);
    return element;
  };

  const initPointer = () => {
    const revealRoot = document.querySelector(REVEAL_SELECTOR);
    if (!revealRoot || document.getElementById(POINTER_ID)) {
      return;
    }

    const pointer = createPointer();
    let enabled = false;

    const hide = () => {
      pointer.classList.remove("is-visible");
    };

    const isWithinReveal = (event) => {
      const rect = revealRoot.getBoundingClientRect();
      return (
        event.clientX >= rect.left &&
        event.clientX <= rect.right &&
        event.clientY >= rect.top &&
        event.clientY <= rect.bottom
      );
    };

    const updatePosition = (event) => {
      if (!enabled) {
        hide();
        return;
      }
      if (!isWithinReveal(event)) {
        hide();
        return;
      }

      pointer.style.left = `${event.clientX}px`;
      pointer.style.top = `${event.clientY}px`;
      pointer.classList.add("is-visible");
    };

    document.addEventListener("keydown", (event) => {
      if (event.defaultPrevented) {
        return;
      }
      if (event.key !== "l" && event.key !== "L") {
        return;
      }
      if (event.ctrlKey || event.metaKey || event.altKey) {
        return;
      }
      if (isEditableTarget(event.target)) {
        return;
      }

      enabled = !enabled;
      if (!enabled) {
        hide();
      }
      event.preventDefault();
      event.stopPropagation();
    }, true);

    document.addEventListener("pointermove", updatePosition, { passive: true });
    revealRoot.addEventListener("pointerleave", hide);
    window.addEventListener("blur", hide);
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState !== "visible") {
        hide();
      }
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initPointer, { once: true });
  } else {
    initPointer();
  }
})();
