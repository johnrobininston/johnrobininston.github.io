<script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.9.3/dist/confetti.browser.min.js"></script>
<script>
  (function () {
    function burst() {
      if (typeof confetti !== "function") return;

      const count = 200;
      const defaults = { origin: { y: 0.62 } };

      function fire(particleRatio, opts) {
        confetti(
          Object.assign({}, defaults, opts, {
            particleCount: Math.floor(count * particleRatio)
          })
        );
      }

      fire(0.25, { spread: 26, startVelocity: 55 });
      fire(0.2, { spread: 60 });
      fire(0.35, { spread: 100, decay: 0.92, scalar: 0.9 });
      fire(0.1, { spread: 120, startVelocity: 25, decay: 0.95, scalar: 1.2 });
      fire(0.1, { spread: 120, startVelocity: 45 });
    }

    function setup() {
      if (typeof Reveal === "undefined" || !Reveal.on) return;

      let hasFired = false;

      Reveal.on("fragmentshown", function (event) {
        if (hasFired) return;
        const fragment = event && event.fragment;
        if (!fragment || !fragment.classList.contains("welcome-trigger")) return;
        hasFired = true;
        burst();
      });
    }

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", setup);
    } else {
      setup();
    }
  })();
</script>
