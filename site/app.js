var selectedUser = null;

$(function(){

  $.ajax({
    url: "orders",
    type: "GET",
  }).success(function(data){
    var orders = JSON.parse(data.orders);
    _.each(orders, function(order){
      if(!(order && order.user)) {
        return;
      }
      var addr = "";
      if(order && order.user && order.user.addresses[0]) {
        addr = order.user.defaultAddress;
      }
      var text = order.user.firstName+" "+order.user.lastName+' -- Total: '+order.total;
      if(addr) {
        text += ' -- Delivery Location: '+ addr;
      }

      $('#orders').append('<li>'+text+'</li>');
    });
  });

  $.ajax({
    url: "users",
    type: "GET",
  }).success(function(data){
    var users = JSON.parse(data.users);
    _.each(users, function(user){
      if(!user) {
        return;
      }
      var addresses = "";
      _.each(user.addresses, function(a) {
        addresses += ("<div>"+a.address1+"</div>")
      });
      var defaultAddr = user.defaultAddress || "No Default Address";
      $('#users').append('<li data-user='+user.id+'><span>'+user.firstName+" "+user.lastName+" -- "+defaultAddr+"</span>"+addresses+'</li>');
    });

    // Bind onclick handler
    $('#users li').click(function(e) {
      $(".selected").removeClass("selected");
      selectedUser = $(this).data('user');
      $(this).addClass("selected");
      $('.user-id').val(selectedUser);
    });
  });

});
