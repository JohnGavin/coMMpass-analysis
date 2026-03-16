// Default to dark mode if no preference stored
if (!localStorage.getItem('theme')) {
  document.documentElement.setAttribute('data-bs-theme', 'dark');
}

// Fix DT htmlwidget: ensure jquery.dataTables.min.js is loaded
// pkgdown + quarto sometimes omits the core DT JS from <script> tags
(function() {
  if (typeof jQuery !== 'undefined' && typeof jQuery.fn.DataTable === 'undefined') {
    var scripts = document.querySelectorAll('script[src*="datatables"]');
    if (scripts.length > 0) {
      var dtCorePath = scripts[0].src.replace(
        /datatables-binding-[^/]+\/datatables\.js/,
        'dt-core-1.13.6/js/jquery.dataTables.min.js'
      );
      var s = document.createElement('script');
      s.src = dtCorePath;
      s.onload = function() {
        // Re-trigger htmlwidgets rendering after DT core loads
        if (window.HTMLWidgets) {
          window.HTMLWidgets.staticRender();
        }
      };
      document.head.appendChild(s);
    }
  }
})();

