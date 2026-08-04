<script>
  (function () {
    var STORAGE_KEY = "pstat10-lecture-theme";
    try {
      var saved = window.localStorage.getItem(STORAGE_KEY);
      var theme = saved === "dark" || saved === "light"
        ? saved
        : (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
      document.documentElement.setAttribute("data-theme", theme);
    } catch (e) {
      // Storage/matchMedia unavailable; default styling (light) applies.
    }
  })();
</script>
