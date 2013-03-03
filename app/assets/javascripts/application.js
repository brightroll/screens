// JS Manifest
//= require jquery
//= require jquery_ujs
//= require jquery.cookie
//= require bootstrap
//= require ckeditor/init
//= require_self

$(document).ready(function() {
  var refresh_timer;

  $('input[name="refresh"]').change(function() {
    if (this.checked) {
      var refresh_count = 15; // Refresh after 15 seconds
      $('span#refresh_countdown').text(refresh_count);
      $.cookie('refresh_welcome_page', 'on', {'path': '/'});

      refresh_timer = setInterval(function() {
        refresh_count--;
        if (refresh_count == 1) {
          $('span#refresh_countdown').html('&hellip;');
        } else if (refresh_count == 0) {
          window.location.reload();
        } else {
          $('span#refresh_countdown').text(refresh_count);
        }
      }, 1000);
    } else {
      clearInterval(refresh_timer);
      $('span#refresh_countdown').text('');
      $.removeCookie('refresh_welcome_page');
    }
  });

  if ($.cookie('refresh_welcome_page')) {
    $('input[name="refresh"]').prop('checked', true);
    $('input[name="refresh"]').change(); // prop does not fire events
  }
});
