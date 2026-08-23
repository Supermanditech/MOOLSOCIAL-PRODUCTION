# C23G Buy test missing destination-model import rejection

The Buy continuity migration used `BuyV2Destination` through the existing
session owner but omitted `features/buy/buy_v2_models.dart`. The focused test
failed compilation. REG-20260809-579 requires exact defining imports for newly
referenced test types. No runtime, host cycle or APK authority changed.
