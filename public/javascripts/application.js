$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This can't be undone!");
    if (ok) {
      this.submit();
    }
  });
  
});