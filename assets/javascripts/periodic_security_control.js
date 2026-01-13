/* Periodic Security Control Plugin JavaScript */

(function() {
  'use strict';

  // Toggle fieldset (for import form)
  window.toggleFieldset = function(legend) {
    var fieldset = legend.parentNode;
    var content = fieldset.querySelector('div');

    if (fieldset.classList.contains('collapsed')) {
      fieldset.classList.remove('collapsed');
      content.style.display = 'block';
    } else {
      fieldset.classList.add('collapsed');
      content.style.display = 'none';
    }
  };

  // Auto-refresh dashboard (optional)
  function initDashboardRefresh() {
    var refreshInterval = 300000; // 5 minutes
    var dashboardContainer = document.querySelector('.psc-summary-cards');

    if (dashboardContainer && window.location.pathname.indexOf('psc_dashboard') > -1) {
      // Could implement auto-refresh here if needed
    }
  }

  // Initialize on page load
  document.addEventListener('DOMContentLoaded', function() {
    initDashboardRefresh();
  });
})();
