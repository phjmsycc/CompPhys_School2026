(function () {
  var slidesRoot = document.querySelector(".reveal .slides");
  if (!slidesRoot) {
    return;
  }

  var candidates = Array.from(slidesRoot.querySelectorAll("section section"));
  candidates.sort(function (a, b) {
    return b.querySelectorAll("section").length - a.querySelectorAll("section").length;
  });

  candidates.forEach(function (section) {
    var parent = section.parentElement;
    if (!parent || parent === slidesRoot) {
      return;
    }
    if (parent.matches(".slides > section.stack")) {
      return;
    }

    var replacement = document.createElement("div");
    Array.from(section.attributes).forEach(function (attribute) {
      replacement.setAttribute(attribute.name, attribute.value);
    });

    while (section.firstChild) {
      replacement.appendChild(section.firstChild);
    }

    parent.replaceChild(replacement, section);
  });
})();
