<script>
  (function () {
    var defaultMathJaxUrl = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js";

    function readDeckMathJaxConfig(mathjaxUrl) {
      var defaults = {
        mathjax: mathjaxUrl,
        tex: {
          inlineMath: [["\\(", "\\)"]],
          displayMath: [["\\[", "\\]"]]
        },
        options: {
          skipHtmlTags: ["script", "noscript", "style", "textarea", "pre", "code"]
        }
      };

      var source = document.getElementById("deck-mathjax-config");
      if (!source) {
        return defaults;
      }

      try {
        var parsed = JSON.parse(source.textContent || "{}");
        if (!parsed || typeof parsed !== "object") {
          return defaults;
        }

        var merged = Object.assign({}, defaults, parsed);
        merged.tex = Object.assign({}, defaults.tex, parsed.tex || {});
        merged.options = Object.assign({}, defaults.options, parsed.options || {});
        return merged;
      } catch (error) {
        console.error("Failed to parse MathJax config", error);
        return defaults;
      }
    }

    function initDeckMathJax() {
      if (document.getElementById("MathJax-script")) {
        return;
      }

      var config = readDeckMathJaxConfig(defaultMathJaxUrl);
      var startup = config && typeof config.startup === "object" && config.startup !== null
        ? config.startup
        : {};
      var originalReady = typeof startup.ready === "function" ? startup.ready : null;
      var url = config.mathjax || defaultMathJaxUrl;

      config.startup = Object.assign({}, startup, {
        ready: function () {
          if (originalReady) {
            originalReady();
          } else if (window.MathJax?.startup?.defaultReady) {
            window.MathJax.startup.defaultReady();
          }

          if (window.MathJax?.startup?.promise?.then) {
            window.MathJax.startup.promise
              .then(function () {
                if (window.Reveal?.layout) {
                  window.Reveal.layout();
                }
              })
              .catch(function (error) {
                console.error("MathJax startup failed", error);
              });
          }
        }
      });

      delete config.mathjax;
      window.MathJax = config;

      var script = document.createElement("script");
      script.type = "text/javascript";
      script.id = "MathJax-script";
      script.src = url;
      script.async = true;
      script.onerror = function (error) {
        console.error("Failed to load MathJax", error);
      };
      document.head.appendChild(script);
    }

    if (window.Reveal?.isReady?.()) {
      initDeckMathJax();
    } else if (window.Reveal?.on) {
      window.Reveal.on("ready", initDeckMathJax);
    } else {
      window.addEventListener("load", initDeckMathJax, { once: true });
    }
  })();
</script>
