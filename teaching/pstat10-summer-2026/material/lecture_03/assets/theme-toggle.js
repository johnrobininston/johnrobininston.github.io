<script>
  (function () {
    var STORAGE_KEY = "pstat10-lecture-theme";
    var root = document.documentElement;
    var media = window.matchMedia("(prefers-color-scheme: dark)");

    function storedTheme() {
      try {
        return window.localStorage.getItem(STORAGE_KEY);
      } catch (e) {
        return null;
      }
    }

    function saveTheme(theme) {
      try {
        window.localStorage.setItem(STORAGE_KEY, theme);
      } catch (e) {
        // Ignore (e.g. privacy mode blocking storage).
      }
    }

    function currentTheme() {
      var saved = storedTheme();
      if (saved === "dark" || saved === "light") return saved;
      return media.matches ? "dark" : "light";
    }

    function applyTheme(theme) {
      root.setAttribute("data-theme", theme);
      var btn = document.getElementById("theme-toggle");
      if (btn) {
        var isDark = theme === "dark";
        btn.textContent = isDark ? "☀️" : "🌙";
        btn.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode");
        btn.setAttribute("title", isDark ? "Switch to light mode" : "Switch to dark mode");
        btn.setAttribute("aria-pressed", String(isDark));
      }
    }

    function toggleTheme() {
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      applyTheme(next);
      saveTheme(next);
    }

    function createButton() {
      if (document.getElementById("theme-toggle")) return;
      var btn = document.createElement("button");
      btn.id = "theme-toggle";
      btn.type = "button";
      btn.addEventListener("click", toggleTheme);
      document.body.appendChild(btn);
      // assets/theme-init.js already set data-theme in <head> to avoid a
      // flash of the wrong theme; just sync the button's icon/labels to it.
      applyTheme(root.getAttribute("data-theme") || currentTheme());
    }

    createButton();

    // Follow system preference changes only if the user hasn't chosen manually.
    media.addEventListener("change", function (e) {
      if (storedTheme()) return;
      applyTheme(e.matches ? "dark" : "light");
    });
  })();
</script>
