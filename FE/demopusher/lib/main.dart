import 'package:demopusher/services/pusher_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    PusherSerivce pusher = PusherSerivce();
    await pusher.init(PusherKeys.demoPusherInit);
    await Future.delayed(const Duration(milliseconds: 500));
  } catch (e) {}

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var showPayment = false;
  bool isPublicChannel = true;
  List<ServiceModel> lstService = [];
  List<ServiceModel> lstPrivateService = [];

  PusherSerivce pusherSerivce = PusherSerivce();

  final _publicChannel = "channel-demo";
  final _publicEvent = 'services';
  final _privateChannel = "private-channel-demo-2";
  final _privateEvent = 'client-services';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _asyncInit();
    });
  }

  _asyncInit() async {
    await pusherSerivce.subscribeChannel(_publicChannel,
        onEvent: (pusherEvent) {
      if (pusherEvent.eventName == _publicEvent) {
        _uploadListService(pusherEvent.data);
      }
    });
    await pusherSerivce.subscribeChannel(_privateChannel,
        onEvent: (pusherEvent) {
      if (pusherEvent.eventName == _privateEvent) {
        _uploadListService(pusherEvent.data);
      }
    });
  }

  @override
  void dispose() {
    pusherSerivce.dispose();
    super.dispose();
  }

  Future<void> _addToCart(ServiceModel item) async {
    final lastLetter = isPublicChannel ? ' Public' : ' Private';
    item = item.copyWith(serviceName: item.serviceName! + lastLetter);

    Map body = {
      'channel': isPublicChannel ? _publicChannel : _privateChannel,
      'event': isPublicChannel ? _publicEvent : _privateEvent,
      'data': item.toRawJson()
    };

    try {
      var url = Uri.parse('http://192.168.1.20:8000/api/pusher/trigger');
      await http.post(url,
          headers: {'Content-type': 'application/json'},
          body: jsonEncode(body));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _uploadListService(String data) {
    setState(() {
      final result = ServiceModel.fromRawJson(data);

      var index = lstService
          .map((e) => e.serviceName)
          .toList()
          .indexOf(result.serviceName);
      if (index == -1) {
        lstService.add(result);
      } else {
        lstService[index] = lstService[index]
            .copyWith(quantity: lstService[index].quantity! + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !showPayment
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => setState(() => isPublicChannel = true),
                    child: Container(
                      color: isPublicChannel ? Colors.red : Colors.grey[300],
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Public Channel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isPublicChannel ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => isPublicChannel = false),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(left: 32),
                      color: !isPublicChannel ? Colors.red : Colors.grey[300],
                      child: Text(
                        'Private Channel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: !isPublicChannel ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  )
                ],
              )
            : Text('Payment'),
      ),
      body: !showPayment
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      itemCount: ServiceModel.demoList.length,
                      itemBuilder: ((context, index) {
                        final item = ServiceModel.demoList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Material(
                            elevation: 8.0,
                            child: ListTile(
                                onTap: () async => _addToCart(item),
                                title: Text(
                                  item.serviceName ?? '',
                                ),
                                subtitle: Text('\$${item.price}'),
                                trailing: const Icon(Icons.add)),
                          ),
                        );
                      })),
                ),
                SafeArea(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        showPayment = !showPayment;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.blue,
                      child: const Center(
                          child: Text(
                        'Payment',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      )),
                    ),
                  ),
                )
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      itemCount: lstService.length,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                      itemBuilder: ((context, index) {
                        final item = lstService[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Material(
                            elevation: 8.0,
                            child: ListTile(
                              onTap: () {},
                              title: Text(
                                item.serviceName ?? '',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text('Price: \$${item.price}'),
                                  Text('Quantity: ${item.quantity}'),
                                ],
                              ),
                            ),
                          ),
                        );
                      })),
                ),
                SafeArea(
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              showPayment = false;
                            });
                          },
                          child: Container(
                            color: Colors.red,
                            height: 64,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 64,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 32),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Total \$${calculateTotalPrice()}',
                              // 'gkjfrsdhijrwhfguik2h4ewuigthewruighiuewmgjofdhnghifdbngifdbnguifdsghuiewhguiewhgew',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  double calculateTotalPrice() => lstService.fold(
      0, (total, element) => total += (element.price! * element.quantity!));
}

class ServiceModel {
  ServiceModel({
    this.serviceName,
    this.price,
    this.quantity,
  });

  final String? serviceName;
  final double? price;
  final int? quantity;

  factory ServiceModel.fromRawJson(String str) =>
      ServiceModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        serviceName: json["serviceName"],
        price: json["price"].toDouble(),
        quantity: json["quantity"],
      );

  Map<String, dynamic> toJson() => {
        "serviceName": serviceName,
        "price": price,
        "quantity": quantity,
      };

  ServiceModel copyWith({
    String? serviceName,
    double? price,
    int? quantity,
  }) =>
      ServiceModel(
        serviceName: serviceName ?? this.serviceName,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
      );

  static final demoList = [
    ServiceModel(serviceName: 'Service A', price: 10.5, quantity: 1),
    ServiceModel(serviceName: 'Service B', price: 16, quantity: 1),
    ServiceModel(serviceName: 'Service C', price: 22.5, quantity: 1),
    ServiceModel(serviceName: 'Service D', price: 32, quantity: 1),
    ServiceModel(serviceName: 'Service E', price: 12.5, quantity: 1),
    ServiceModel(serviceName: 'Service F', price: 8.5, quantity: 1)
  ];
}
