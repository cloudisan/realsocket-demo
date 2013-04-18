require.define("/app", function (require, module, exports, __dirname, __filename){
/* QUICK CHAT DEMO
*/

var pad2, timestamp, valid;

ss.event.on('newMessage', function(message) {
  var html;
  html = ss.tmpl['chat-message'].render({
    message: message,
    time: function() {
      return timestamp();
    }
  });
  return $(html).hide().appendTo('#chatlog').slideDown();
});

$('#demo').on('submit', function() {
  var text;
  text = $('#myMessage').val();
  return exports.send(text, function(success) {
    if (success) {
      return $('#myMessage').val('');
    } else {
      return alert('Oops! Unable to send message');
    }
  });
});

exports.send = function(text, cb) {
  if (valid(text)) {
    return ss.rpc('demo.sendMessage', text, cb);
  } else {
    return cb(false);
  }
};

timestamp = function() {
  var d;
  d = new Date();
  return d.getHours() + ':' + pad2(d.getMinutes()) + ':' + pad2(d.getSeconds());
};

pad2 = function(number) {
  return (number < 10 ? '0' : '') + number;
};

valid = function(text) {
  return text && text.length > 0;
};

});