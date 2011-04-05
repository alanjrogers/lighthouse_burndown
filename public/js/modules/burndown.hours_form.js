jQuery.fn.hoursForm = function(){
  return this.each(function(){
    var form = $(this);
    var loader = form.find('.loader');
    var message = form.find('.message');
    var state = 'check';
    
    var saveHours = function(){
      $.ajax({
        type: 'POST',
        url: form.attr('action'),
        data: form.serialize(),
        success: function(){
          loader.text('Hours per day saved successfully!');
          message.text('Your change has been saved!').removeClass('error').addClass('success').show();
          setTimeout(function(){ loader.removeClass('success').hide() }, 2000);
          document.location = document.location;
          state = 'check';
        },
        error: function(){
          loader.text('Error updating hours per day').addClass('error');
          message.text('Your change did not save correctly. Make sure you are entering a valid float value.').addClass('error').show();
          setTimeout(function(){ loader.removeClass('error').hide() }, 2000);
          state = 'check';
        }
      })
    }
    
    form.submit(function(){
      if (state == 'requesting') return false;
      saveHours();
      loader.text('Updating Hours per day for project...').show();
      state = 'requesting';
      return false;
    })
  });
}