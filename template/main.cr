MAIN_TEMPLATE = <<-HTML
<!doctype html>
<html>
  <body>
  
    <div class="input">
          <img class="logo" draggable="false" src="data:image/png;base64, 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" />
        <p>IP Address:</p>
        <input type="text" id="ipAddress" placeholder="ex: 186.54.38.95">
        <p>Port:</p>
        <input type="text" id="port" name="port" placeholder="ex: 443">
        <p>SNI:</p>
        <input type="text" id="sni" name="sni" placeholder="ex: google.com">
    </div>
    <div class="status">
      <p>Status: <span id="statusText">disconnected</span></p>
    </div>
    <div class="buttons">
      <button onclick="connect()">Connect</button>
      <button onclick="disconnect()">Disconnect</button>
    </div>
  </body>
 
  <script>
    document.addEventListener("contextmenu", (event) => {
         event.preventDefault();
    });

    function connect()
    {
        var ip = document.getElementById("ipAddress").value
        var port = document.getElementById("port").value
        var sni = document.getElementById("sni").value
        var status = document.getElementById("statusText")
        proxy_connect(ip, port, sni).then(function(res){
            json = JSON.parse(res)
            status.innerText = json["message"]
        })
    }
    function disconnect()
    {
        var status = document.getElementById("statusText")
        proxy_disconnect().then(function(){
            status.innerText = "disconnected"
        })
    }
  </script>

  <style>
    *{
        font-family: Arial, Helvetica, sans-serif;
        -webkit-user-select: none; /* Safari */
        -ms-user-select: none; /* IE 10 and IE 11 */
        user-select: none; /* Standard syntax */
        margin:0;
        padding:0;
    }
    span{
        font-style: italic;
    }
    body{
        margin: 0 10px;
    }

    .logo{
        margin:0 auto;
        margin-bottom: 20px;
        width:250px;
    }
    .input{
        margin:20px auto;
        display: flex;
        flex-direction: column;

    }
    .input input{
        margin: 5px 0;
        padding: 5px;
        outline-color: #667689;
    }
    .input p{
        color: #667689;
        font-weight: bold;
    }

    .status{
      margin:20px auto;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      
    }

    .status p{
      color:#667689;
    }

    .buttons{
      margin:20px auto;
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: space-evenly;
      text-align: center;
    }
    .buttons button{
      cursor: pointer;
      padding: 10px 20px;
      background: #667689;
      border: none;
      color: #fff;
      font-weight: bold;
      transition: 0.2s;
    }

    .buttons button:hover{
      background: #4c5866;
    }


  </style>
</html>
HTML