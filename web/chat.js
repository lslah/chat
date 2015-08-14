var ChatApp = React.createClass({
  getInitialState: function() {
    return {chat: [{name: "thomas", msg: "test"}]};
  },
  componentDidMount: function () {
    this.loadChat();
    setInterval(this.loadChat, 500);
  },
  loadChat: function () {
    $.getJSON("/chat", null, this.updateMessage);
  },
  updateMessage: function(data) {
    this.setState({chat: data});
  },
  render: function() {
    return (
      <div className="chatApp">
        <InputField updateMessage={this.updateMessage} submitCallback={this.submitCallback} checked={this.state.checked} />
        <ChatWindow chat={this.state.chat} checked={this.state.checked} />
      </div>
    );
  }
});

var InputField = React.createClass({
  getInitialState: function () {
    return {message: '', username: 'Guest'};
  },
  handleUsernameChange: function (e) {
    this.setState({username: e.target.value});
  },
  handleMessageChange: function (e) {
    this.setState({message: e.target.value});
  },
  handleSubmit: function (e) {
    e.preventDefault();
    console.log(this.state.username + ': ' + this.state.message);

    $.ajax({
        type: "POST",
        url: '/write',
        data: JSON.stringify({name: this.state.username, msg: this.state.message}),
        contentType: 'application/json; charset=utf-8',
        error: function (xhr, stat, errthrown) {
          console.log(xhr);
        },
        success: this.props.updateMessage
    });
    this.setState({message: ''});
  },
  render: function() {
    return (
        <form className="inputForm" onSubmit={this.handleSubmit}>
          <input className="usernameField" type="text" name="username" value={this.state.username} onChange={this.handleUsernameChange} />
          <br />
          <input style={{width:"300px"}} onKeyPress={this.submitEnter} className="messageField" type="text" name="message" value={this.state.message} onChange={this.handleMessageChange} />
          <input type="submit" />
        </form>
    );
  }
});

var ChatWindow = React.createClass({
  render: function() {
    var chat = this.props.chat.map(function (msg) {
      return <li>{msg.name} ({msg.time}): {msg.msg}</li>
    });

    return (
        <div className="mainBox">
          <ul> {chat} </ul>
        </div>
    );
  }
});


React.render(
    <ChatApp />,
    document.getElementById('app')
);
