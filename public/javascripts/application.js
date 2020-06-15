$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This can't be undone!");
    if (ok) {      
      var form = $(this);

      var request = $.ajax({ // use ajax
        url: form.attr("action"), // extracted from form element
        method: form.attr("method") // extracted from form element
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").remove()
        } else if (jqXHR.status == 200) {
          document.location = data;
        }
      });
    }
  });

});