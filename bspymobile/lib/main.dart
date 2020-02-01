import 'package:battery/battery.dart';
import 'package:bspymobile/services/battery_notification.dart';
import 'package:flutter/material.dart';
import 'package:udp/udp.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BSPY',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      home: Home(title: 'Battery Spy'),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isTransmitter = true;
  bool _broadcastCharging = false;
  bool _isReceiver = false;
  BatteryState _prev;
  BatteryNotification notification;
  static const _PAYLOAD = "0X0X0";
  UDP _sender, _receiver;
  String _message = "Message here";

  Future<void> _init() async {
    if (_sender == null) {
      UDP sender = await UDP.bind(
        Endpoint.any(
          port: Port(8887),
        ),
      );
      sender.socket.broadcastEnabled = true;
      setState(() {
        _sender = sender;
      });
    }
  }

  @override
  void initState() {
    notification = BatteryNotification();
    Battery battery = Battery();
    battery.onBatteryStateChanged.listen((BatteryState state) {
      _handleBatteryState(state);
    });
    super.initState();
  }

  void listenForBroadCast() {
    UDP.bind(Endpoint.any(port: Port(8889))).then((receiver) {
      receiver.listen((datagram) {
        String str = String.fromCharCodes(datagram.data);
        if (str == _PAYLOAD) {
          print("ALERT!!!!");
          setState(() {
            _message = "ALERT!!";
          });
          notification.show();
        } else {
          setState(() {
            _message = "A broadcast: " + str;
          });
        }
        setState(() => _receiver = receiver);
      });
    });
  }

  void sendBroadcast() async {
    if (_sender != null && _isTransmitter) {
      var dataLength = await _sender.send(
        _PAYLOAD.codeUnits,
        Endpoint.broadcast(
          port: Port(8889),
        ),
      );
      print("$dataLength bytes sent.");
    }
  }

  void _handleBatteryState(BatteryState state) async {
    if (state == _prev) {
      return;
    }
    if (state == BatteryState.charging) {
      setState(() {
        _message = "Charging";
        _prev = state;
      });
      if (_broadcastCharging) {
        sendBroadcast();
      }
    } else if (state == BatteryState.discharging) {
      setState(() {
        _message = "Discharging";
        _prev = state;
      });
      if (!_broadcastCharging) {
        sendBroadcast();
      }
    } else {
      setState(() {
        _message = "Full";
      });
    }
  }

  @override
  void dispose() {
    if (_sender != null) {
      _sender.close();
    }
    if (_receiver != null) {
      _receiver.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
          color: Color(0xff0f0f0f),
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Transmitter"),
                    Switch(
                      value: _isTransmitter,
                      onChanged: (value) => setState(
                        () => _isTransmitter = value,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Discharging/Charging",
                      style: TextStyle(
                        color: _isTransmitter ? Colors.white : Colors.grey,
                      ),
                    ),
                    Switch(
                      value: _broadcastCharging,
                      onChanged: _isTransmitter
                          ? (value) =>
                              setState(() => _broadcastCharging = value)
                          : null,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Receiver"),
                    Switch(
                      value: _isReceiver,
                      onChanged: (value) {
                        if (value) {
                          listenForBroadCast();
                        } else if (_receiver != null) {
                          _receiver.close();
                        }
                        setState(() => _isReceiver = value);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(32),
                ),
                Text(
                  _message,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
