class AppUser {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String role;
  final List<String> favouriteShopIds;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    this.favouriteShopIds = const [],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
        uid: uid,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        mobile: (data['mobile'] as String?) ?? '',
        role: (data['role'] as String?) ?? 'customer',
        favouriteShopIds: ((data['favouriteShopIds'] as List<dynamic>?) ?? const []).map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'mobile': mobile,
        'role': role,
        'favouriteShopIds': favouriteShopIds,
      };
}

class Shop {
  final String ownerId;
  final String shopName;
  final String ownerName;
  final String mobile;
  final String location;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final bool bookingsAvailable;
  final String address;
  final String openTime;
  final String closeTime;
  final String shopPhotoUrl;
  final List<dynamic> gallery;
  final List<ShopService> services;
  final int totalSeats;
  final int occupiedSeats;
  final int bookingPrice;
  final int premiumBookingPrice;
  final List<int> workingDays;
  final String description;
  final String accessStatus;
  final int chairCount;
  final int notificationThreshold;
  final String tokenDate;
  final String partnerCode;
  final String chairAvailabilityDate;
  final int availableChairs;

  const Shop({
    required this.ownerId,
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    this.bookingsAvailable = true,
    required this.address,
    required this.openTime,
    required this.closeTime,
    required this.shopPhotoUrl,
    this.gallery = const [],
    required this.services,
    this.totalSeats = 10,
    this.occupiedSeats = 0,
    this.bookingPrice = 50,
    this.premiumBookingPrice = 0,
    this.workingDays = const [1, 2, 3, 4, 5, 6, 7],
    this.description = '',
    this.accessStatus = 'pending',
    this.chairCount = 1,
    this.notificationThreshold = 5,
    this.tokenDate = '',
    this.partnerCode = '',
    this.chairAvailabilityDate = '',
    this.availableChairs = 0,
  });

  int get availableSeats => totalSeats - occupiedSeats;

  factory Shop.fromMap(String ownerId, Map<String, dynamic> data) {
    final serviceList = data['services'] as List<dynamic>? ?? [];
    return Shop(
      ownerId: ownerId,
      shopName: (data['shopName'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      mobile: (data['mobile'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      latitude: ((data['latitude'] as num?) ?? 0).toDouble(),
      longitude: ((data['longitude'] as num?) ?? 0).toDouble(),
      isOpen: data['isOpen'] == true,
      bookingsAvailable: data['bookingsAvailable'] == true,
      address: (data['address'] as String?) ?? '',
      openTime: (data['openTime'] as String?) ?? '',
      closeTime: (data['closeTime'] as String?) ?? '',
      shopPhotoUrl: (data['shopPhotoUrl'] as String?) ?? '',
      gallery: (data['gallery'] as List<dynamic>?) ?? [],
      services: serviceList.map((e) => ShopService.fromMap(Map<String, dynamic>.from(e))).toList(),
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 10,
      occupiedSeats: (data['occupiedSeats'] as num?)?.toInt() ?? 0,
      bookingPrice: (data['bookingPrice'] as num?)?.toInt() ?? 50,
      premiumBookingPrice: (data['premiumBookingPrice'] as num?)?.toInt() ?? 0,
      workingDays: (data['workingDays'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [1, 2, 3, 4, 5, 6, 7],
      description: (data['description'] as String?) ?? '',
      accessStatus: (data['accessStatus'] as String?) ?? 'pending',
      chairCount: (data['chairCount'] as num?)?.toInt() ?? 1,
      notificationThreshold: (data['notificationThreshold'] as num?)?.toInt() ?? 5,
      tokenDate: (data['tokenDate'] as String?) ?? '',
      partnerCode: (data['partnerCode'] as String?) ?? '',
      chairAvailabilityDate: (data['chairAvailabilityDate'] as String?) ?? '',
      availableChairs: (data['availableChairs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'shopName': shopName,
        'ownerName': ownerName,
        'mobile': mobile,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'isOpen': isOpen,
        'bookingsAvailable': bookingsAvailable,
        'address': address,
        'openTime': openTime,
        'closeTime': closeTime,
        'shopPhotoUrl': shopPhotoUrl,
        'gallery': gallery,
        'services': services.map((s) => s.toMap()).toList(),
        'totalSeats': totalSeats,
        'occupiedSeats': occupiedSeats,
        'bookingPrice': bookingPrice,
        'premiumBookingPrice': premiumBookingPrice,
        'workingDays': workingDays,
        'description': description,
        'accessStatus': accessStatus,
        'chairCount': chairCount,
        'notificationThreshold': notificationThreshold,
        'tokenDate': tokenDate,
        'partnerCode': partnerCode,
        'chairAvailabilityDate': chairAvailabilityDate,
        'availableChairs': availableChairs,
        'updatedAt': DateTime.now().toIso8601String(),
      };
}

class Chair {
  final String ownerId;
  final int chairNumber;
  final int? currentToken;
  final String? customerName;
  final String? customerId;
  final String? customerNameDisplay;
  final String? serviceName;
  final DateTime? startTime;
  final DateTime? predictedEndTime;
  final int durationMinutes;
  final int remainingSeconds;
  final String status;
  final int? nextAssignedToken;
  final bool notificationSent;

  const Chair({
    required this.ownerId,
    required this.chairNumber,
    this.currentToken,
    this.customerName,
    this.customerId,
    this.customerNameDisplay,
    this.serviceName,
    this.startTime,
    this.predictedEndTime,
    this.durationMinutes = 30,
    this.remainingSeconds = 0,
    this.status = 'available',
    this.nextAssignedToken,
    this.notificationSent = false,
  });

  String get docId => '${ownerId}_chair_$chairNumber';

  /// Calculates remaining seconds from predicted end time.
  /// Returns 0 if no active service or already past end time.
  int get effectiveRemainingSeconds {
    if (status != 'in_service' || predictedEndTime == null) return remainingSeconds;
    final diff = predictedEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  factory Chair.fromMap(String id, Map<String, dynamic> data) => Chair(
    ownerId: (data['ownerId'] as String?) ?? '',
    chairNumber: (data['chairNumber'] as num?)?.toInt() ?? 1,
    currentToken: (data['currentToken'] as num?)?.toInt(),
    customerName: data['customerName'] as String?,
    customerId: data['customerId'] as String?,
    customerNameDisplay: data['customerNameDisplay'] as String?,
    serviceName: data['serviceName'] as String?,
    startTime: data['startTime'] is String ? DateTime.tryParse(data['startTime'] as String) : null,
    predictedEndTime: data['predictedEndTime'] is String ? DateTime.tryParse(data['predictedEndTime'] as String) : null,
    durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
    remainingSeconds: (data['remainingSeconds'] as num?)?.toInt() ?? 0,
    status: (data['status'] as String?) ?? 'available',
    nextAssignedToken: (data['nextAssignedToken'] as num?)?.toInt(),
    notificationSent: data['notificationSent'] == true,
  );

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'chairNumber': chairNumber,
    'currentToken': currentToken,
    'customerName': customerName,
    'customerId': customerId,
    'customerNameDisplay': customerNameDisplay,
    'serviceName': serviceName,
    'startTime': startTime?.toIso8601String(),
    'predictedEndTime': predictedEndTime?.toIso8601String(),
    'durationMinutes': durationMinutes,
    'remainingSeconds': remainingSeconds,
    'status': status,
    'nextAssignedToken': nextAssignedToken,
    'notificationSent': notificationSent,
    'updatedAt': DateTime.now().toIso8601String(),
  };

  Chair copyWith({
    int? currentToken,
    String? customerName,
    String? customerId,
    String? customerNameDisplay,
    String? serviceName,
    DateTime? startTime,
    DateTime? predictedEndTime,
    int? durationMinutes,
    int? remainingSeconds,
    String? status,
    int? nextAssignedToken,
    bool? notificationSent,
  }) => Chair(
    ownerId: ownerId,
    chairNumber: chairNumber,
    currentToken: currentToken ?? this.currentToken,
    customerName: customerName ?? this.customerName,
    customerId: customerId ?? this.customerId,
    customerNameDisplay: customerNameDisplay ?? this.customerNameDisplay,
    serviceName: serviceName ?? this.serviceName,
    startTime: startTime ?? this.startTime,
    predictedEndTime: predictedEndTime ?? this.predictedEndTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    status: status ?? this.status,
    nextAssignedToken: nextAssignedToken ?? this.nextAssignedToken,
    notificationSent: notificationSent ?? this.notificationSent,
  );
}

class ShopService {
  final String name;
  final int price;
  final int durationMinutes;
  final bool enabled;
  final String photoUrl;
  final List<dynamic> serviceImages;

  const ShopService({
    required this.name,
    required this.price,
    this.durationMinutes = 30,
    this.enabled = true,
    required this.photoUrl,
    this.serviceImages = const [],
  });

  factory ShopService.fromMap(Map<String, dynamic> data) => ShopService(
        name: (data['name'] as String?) ?? '',
        price: (data['price'] as num?)?.toInt() ?? 0,
        durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
        enabled: data['enabled'] == true,
        photoUrl: (data['photoUrl'] as String?) ?? '',
        serviceImages: (data['serviceImages'] as List<dynamic>?) ?? [],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
        'enabled': enabled,
        'photoUrl': photoUrl,
        'serviceImages': serviceImages,
      };

  ShopService copyWith({String? name, int? price, int? durationMinutes, bool? enabled, String? photoUrl, List<dynamic>? serviceImages}) =>
      ShopService(
        name: name ?? this.name,
        price: price ?? this.price,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        enabled: enabled ?? this.enabled,
        photoUrl: photoUrl ?? this.photoUrl,
        serviceImages: serviceImages ?? this.serviceImages,
      );
}

class Booking {
  final String id;
  final String ownerId;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String shopName;
  final String serviceName;
  final int price;
  final int bookingPrice;
  final int remainingAmount;
  final String paymentMethod;
  final int token;
  final String status;
  final bool reachedShop;
  final bool isPaid;
  final bool offlinePaymentRequested;
  final bool isPremium;
  final int premiumDaysAhead;
  final int premiumExtraPrice;
  final DateTime createdAt;
  final int durationMinutes;
  final String scheduledDate;
  final String scheduledTime;
  final String preferredTime1;
  final String preferredTime2;
  final String preferredTime3;
  final DateTime? cancelledAt;
  final int? chairNumber;

  const Booking({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.shopName,
    required this.serviceName,
    required this.price,
    this.bookingPrice = 0,
    this.remainingAmount = 0,
    required this.paymentMethod,
    required this.token,
    required this.status,
    this.reachedShop = false,
    this.isPaid = false,
    this.offlinePaymentRequested = false,
    this.isPremium = false,
    this.premiumDaysAhead = 0,
    this.premiumExtraPrice = 0,
    required this.createdAt,
    this.durationMinutes = 30,
    this.scheduledDate = '',
    this.scheduledTime = '',
    this.preferredTime1 = '',
    this.preferredTime2 = '',
    this.preferredTime3 = '',
    this.cancelledAt,
    this.chairNumber,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> data) => Booking(
        id: id,
        ownerId: (data['ownerId'] as String?) ?? '',
        customerId: (data['customerId'] as String?) ?? '',
        customerName: (data['customerName'] as String?) ?? '',
        customerMobile: (data['customerMobile'] as String?) ?? '',
        shopName: (data['shopName'] as String?) ?? '',
        serviceName: (data['serviceName'] as String?) ?? '',
        price: (data['price'] as num?)?.toInt() ?? 0,
        bookingPrice: (data['bookingPrice'] as num?)?.toInt() ?? 0,
        remainingAmount: (data['remainingAmount'] as num?)?.toInt() ?? 0,
        paymentMethod: (data['paymentMethod'] as String?) ?? '',
        token: (data['token'] as num?)?.toInt() ?? 0,
        status: (data['status'] as String?) ?? 'pending',
        reachedShop: data['reachedShop'] == true,
        isPaid: data['isPaid'] == true,
        offlinePaymentRequested: data['offlinePaymentRequested'] == true,
        isPremium: data['isPremium'] == true,
        premiumDaysAhead: (data['premiumDaysAhead'] as num?)?.toInt() ?? 0,
        premiumExtraPrice: (data['premiumExtraPrice'] as num?)?.toInt() ?? 0,
        createdAt: (data['createdAt'] is String ? DateTime.tryParse(data['createdAt'] as String) : null) ?? DateTime.now(),
        durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
        scheduledDate: (data['scheduledDate'] as String?) ?? '',
        scheduledTime: (data['scheduledTime'] as String?) ?? '',
        preferredTime1: (data['preferredTime1'] as String?) ?? '',
        preferredTime2: (data['preferredTime2'] as String?) ?? '',
        preferredTime3: (data['preferredTime3'] as String?) ?? '',
        cancelledAt: data['cancelledAt'] is String ? DateTime.tryParse(data['cancelledAt'] as String) : null,
        chairNumber: (data['chairNumber'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'customerId': customerId,
        'customerName': customerName,
        'customerMobile': customerMobile,
        'shopName': shopName,
        'serviceName': serviceName,
        'price': price,
        'bookingPrice': bookingPrice,
        'remainingAmount': remainingAmount,
        'paymentMethod': paymentMethod,
        'token': token,
        'status': status,
        'reachedShop': reachedShop,
        'isPaid': isPaid,
        'offlinePaymentRequested': offlinePaymentRequested,
        'isPremium': isPremium,
        'premiumDaysAhead': premiumDaysAhead,
        'premiumExtraPrice': premiumExtraPrice,
        'createdAt': createdAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'preferredTime1': preferredTime1,
        'preferredTime2': preferredTime2,
        'preferredTime3': preferredTime3,
        'cancelledAt': cancelledAt?.toIso8601String(),
        'chairNumber': chairNumber,
      };

  Booking copyWith({
    String? id,
    String? status,
    bool? reachedShop,
    bool? isPaid,
    bool? offlinePaymentRequested,
    int? price,
    int? remainingAmount,
    DateTime? cancelledAt,
    int? chairNumber,
    String? scheduledDate,
    String? scheduledTime,
    String? preferredTime1,
    String? preferredTime2,
    String? preferredTime3,
  }) =>
      Booking(
        id: id ?? this.id,
        ownerId: ownerId,
        customerId: customerId,
        customerName: customerName,
        customerMobile: customerMobile,
        shopName: shopName,
        serviceName: serviceName,
        price: price ?? this.price,
        bookingPrice: bookingPrice,
        remainingAmount: remainingAmount ?? this.remainingAmount,
        paymentMethod: paymentMethod,
        token: token,
        status: status ?? this.status,
        reachedShop: reachedShop ?? this.reachedShop,
        isPaid: isPaid ?? this.isPaid,
        offlinePaymentRequested: offlinePaymentRequested ?? this.offlinePaymentRequested,
        isPremium: isPremium,
        premiumDaysAhead: premiumDaysAhead,
        premiumExtraPrice: premiumExtraPrice,
        createdAt: createdAt,
        durationMinutes: durationMinutes,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        preferredTime1: preferredTime1 ?? this.preferredTime1,
        preferredTime2: preferredTime2 ?? this.preferredTime2,
        preferredTime3: preferredTime3 ?? this.preferredTime3,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        chairNumber: chairNumber ?? this.chairNumber,
      );
}

class Queue {
  final int currentToken;
  final String currentCustomer;
  final int estimatedMinutes;
  final bool isActive;

  const Queue({
    this.currentToken = 0,
    this.currentCustomer = '',
    this.estimatedMinutes = 30,
    this.isActive = false,
  });

  factory Queue.fromMap(Map<String, dynamic> data) => Queue(
        currentToken: (data['currentToken'] as num?)?.toInt() ?? 0,
        currentCustomer: (data['currentCustomer'] as String?) ?? '',
        estimatedMinutes: (data['estimatedMinutes'] as num?)?.toInt() ?? 30,
        isActive: data['isActive'] == true,
      );

  Map<String, dynamic> toMap() => {
        'currentToken': currentToken,
        'currentCustomer': currentCustomer,
        'estimatedMinutes': estimatedMinutes,
        'isActive': isActive,
      };
}

class ServiceTimer {
  final String ownerId;
  final int token;
  final DateTime? startTime;
  final int durationMinutes;
  final int elapsedSeconds;
  final String status;

  const ServiceTimer({
    required this.ownerId,
    required this.token,
    this.startTime,
    this.durationMinutes = 30,
    this.elapsedSeconds = 0,
    this.status = 'idle',
  });

  factory ServiceTimer.fromMap(String ownerId, Map<String, dynamic> data) => ServiceTimer(
        ownerId: ownerId,
        token: (data['token'] as num?)?.toInt() ?? 0,
        startTime: data['startTime'] != null ? DateTime.tryParse(data['startTime'] as String) : null,
        durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
        elapsedSeconds: (data['elapsedSeconds'] as num?)?.toInt() ?? 0,
        status: (data['status'] as String?) ?? 'idle',
      );

  Map<String, dynamic> toMap() => {
        'token': token,
        'startTime': startTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'elapsedSeconds': elapsedSeconds,
        'status': status,
      };
}

class PremiumSlot {
  final String ownerId;
  final int daysAhead;
  final int extraPrice;
  final int slotsAvailable;

  const PremiumSlot({
    required this.ownerId,
    required this.daysAhead,
    this.extraPrice = 0,
    this.slotsAvailable = 5,
  });

  factory PremiumSlot.fromMap(Map<String, dynamic> data) => PremiumSlot(
        ownerId: (data['ownerId'] as String?) ?? '',
        daysAhead: (data['daysAhead'] as num?)?.toInt() ?? 0,
        extraPrice: (data['extraPrice'] as num?)?.toInt() ?? 0,
        slotsAvailable: (data['slotsAvailable'] as num?)?.toInt() ?? 5,
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'daysAhead': daysAhead,
        'extraPrice': extraPrice,
        'slotsAvailable': slotsAvailable,
      };
}

class AppNotification {
  final String id;
  final String ownerId;
  final String? customerId;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.ownerId,
    this.customerId,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) => AppNotification(
        id: id,
        ownerId: (data['ownerId'] as String?) ?? '',
        customerId: data['customerId'] as String?,
        title: (data['title'] as String?) ?? '',
        body: (data['body'] as String?) ?? '',
        read: data['read'] == true,
        createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        if (customerId != null) 'customerId': customerId,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };
}

class AccessRequest {
  final String id;
  final String ownerId;
  final String ownerName;
  final String shopName;
  final String mobile;
  final String status;
  final String note;
  final DateTime createdAt;

  const AccessRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.shopName,
    required this.mobile,
    required this.status,
    this.note = '',
    required this.createdAt,
  });

  factory AccessRequest.fromMap(String id, Map<String, dynamic> data) => AccessRequest(
    id: id,
    ownerId: (data['ownerId'] as String?) ?? '',
    ownerName: (data['ownerName'] as String?) ?? '',
    shopName: (data['shopName'] as String?) ?? '',
    mobile: (data['mobile'] as String?) ?? '',
    status: (data['status'] as String?) ?? 'pending',
    note: (data['note'] as String?) ?? '',
    createdAt: DateTime.tryParse((data['createdAt'] as String?) ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'ownerName': ownerName,
    'shopName': shopName,
    'mobile': mobile,
    'status': status,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };
}

enum EarningsPeriod { all, day, week, month, year }

DateTime earningsPeriodStart(EarningsPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case EarningsPeriod.all:
      return DateTime(0);
    case EarningsPeriod.day:
      return today;
    case EarningsPeriod.week:
      return today.subtract(Duration(days: today.weekday - 1));
    case EarningsPeriod.month:
      return DateTime(now.year, now.month);
    case EarningsPeriod.year:
      return DateTime(now.year);
  }
}

class ShopEarnings {
  final String ownerId;
  final String shopName;
  final String partnerCode;
  final String partnerName;
  final int totalRevenue;
  final int totalBookingCharges;
  final int bookingCount;

  const ShopEarnings({
    required this.ownerId,
    required this.shopName,
    this.partnerCode = '',
    this.partnerName = '',
    required this.totalRevenue,
    required this.totalBookingCharges,
    required this.bookingCount,
  });
}

class PartnerEarnings {
  final String partnerCode;
  final String partnerName;
  final int totalRevenue;
  final int totalBookingCharges;
  final int bookingCount;
  final int shopCount;

  const PartnerEarnings({
    required this.partnerCode,
    required this.partnerName,
    required this.totalRevenue,
    required this.totalBookingCharges,
    required this.bookingCount,
    required this.shopCount,
  });
}
