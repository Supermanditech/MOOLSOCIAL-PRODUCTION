import 'package:flutter/foundation.dart';

import 'book_models.dart';
import 'book_services.dart';

class BookSession extends ChangeNotifier {
  BookSession({BookGateway? gateway})
    : gateway = gateway ?? ReviewBookGateway();

  final BookGateway gateway;

  bool busy = false;
  String? noticeMessage;
  String? errorMessage;

  DoctorCare doctorCare = DoctorCare.clinic;
  String doctorNeed = 'Fever';
  String patient = 'Self';
  int? childAge;
  final Set<String> symptoms = {'Fever'};
  bool prescriptionAttached = true;
  bool reportAttached = false;
  bool medicalConsent = false;
  DoctorAppointment? appointment;
  bool clinicInviteConsent = false;
  bool clinicInviteJoined = false;
  bool clinicSharing = true;
  bool followUpReportUploaded = false;
  bool medicineReminder = false;
  bool prescriptionInviteQrAdded = false;
  String? receptionInviteCode;
  String? followUpSlot;

  String salonService = 'Haircut';
  SalonMode salonMode = SalonMode.salon;
  SalonPayment salonPayment = SalonPayment.atSalon;
  String salonAddon = 'No add-on';
  int salonAmount = 199;
  SalonBooking? salonBooking;
  bool salonCheckedIn = false;
  bool salonServiceDone = false;
  bool salonPaid = false;
  int salonRating = 0;
  SalonIssue salonIssue = SalonIssue.bill;
  BookSupportCase? salonSupportCase;

  String taskCity = 'Jodhpur';
  TaskType taskType = TaskType.pickup;
  String taskDetail = '';
  TaskPayment taskPayment = TaskPayment.upi;
  LocalTask? task;
  bool taskProofReceived = false;
  bool taskReleased = false;
  int taskRating = 0;
  bool helperSaved = false;
  TaskIssue taskIssue = TaskIssue.wrongProof;
  BookSupportCase? taskSupportCase;
  TaskResolution taskResolution = TaskResolution.refund;
  bool resolutionComplete = false;

  int get salonAddonAmount => switch (salonAddon) {
    'Beard' => 80,
    'Wash' => 120,
    'Cleanup' => 350,
    _ => 0,
  };

  int get salonTotal => salonAmount + salonAddonAmount;

  int get taskFee => 99;
  int get taskSpendLimit => 500;
  int get taskHeldAmount => taskFee + taskSpendLimit;
  int get taskActualSpend => 420;
  int get taskReleaseAmount => taskFee + taskActualSpend;
  int get taskReturnAmount => taskSpendLimit - taskActualSpend;

  void showNotice(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  void showError(String message) {
    noticeMessage = null;
    errorMessage = message;
    notifyListeners();
  }

  void clearMessages() {
    noticeMessage = null;
    errorMessage = null;
    notifyListeners();
  }

  String get secureClinicInviteLink {
    final reference = appointment?.id ?? 'clinic-care';
    return 'https://moolsocial.com/i/$reference';
  }

  void addInviteQrToPrescription() {
    if (prescriptionInviteQrAdded) {
      showNotice('The patient invite QR is already on the prescription.');
      return;
    }
    prescriptionInviteQrAdded = true;
    showNotice('Patient invite QR added to the prescription.');
  }

  void createReceptionInviteCode() {
    if (receptionInviteCode != null) {
      showNotice('The active reception code remains unchanged.');
      return;
    }
    final reference = appointment?.id ?? 'clinic-care';
    final value = reference.codeUnits.fold<int>(
      0,
      (total, unit) => (total * 31 + unit) % 900000,
    );
    receptionInviteCode = (value + 100000).toString();
    showNotice('One-time reception code created.');
  }

  void chooseFollowUpSlot(String value) {
    followUpSlot = value;
    showNotice('$value follow-up booked.');
  }

  void prepareDoctor() {
    clearMessages();
  }

  void chooseDoctorCare(DoctorCare value) {
    doctorCare = value;
    showNotice('${value.label} selected.');
  }

  void chooseDoctorNeed(String value) {
    doctorNeed = value;
    symptoms
      ..clear()
      ..add(value);
    showNotice('$value selected.');
  }

  void choosePatient(String value) {
    patient = value;
    childAge = null;
    clearMessages();
  }

  bool saveChildAge(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1 || parsed > 17) {
      showError('Enter the child’s age from 1 to 17 years.');
      return false;
    }
    childAge = parsed;
    patient = 'Child';
    showNotice('Child age $parsed saved.');
    return true;
  }

  void toggleSymptom(String value) {
    if (!symptoms.add(value)) symptoms.remove(value);
    notifyListeners();
  }

  void toggleReport() {
    reportAttached = !reportAttached;
    showNotice(reportAttached ? 'Lab report attached.' : 'Lab report removed.');
  }

  void setMedicalConsent(bool value) {
    medicalConsent = value;
    clearMessages();
  }

  Future<bool> confirmDoctorDetails() async {
    if (busy) return false;
    if (patient == 'Child' && childAge == null) {
      showError('Add the child’s age before confirming.');
      return false;
    }
    if (symptoms.isEmpty) {
      showError('Choose at least one symptom or reason for the appointment.');
      return false;
    }
    if (!medicalConsent) {
      showError('Allow sharing with this verified doctor to confirm.');
      return false;
    }
    busy = true;
    clearMessages();
    try {
      appointment = await gateway.confirmDoctorAppointment(
        patient: patient,
        care: doctorCare,
        need: symptoms.join(', '),
      );
      noticeMessage =
          'Appointment ${appointment!.id} confirmed for today at 6:20 PM.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage =
          'The appointment status could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setClinicInviteConsent(bool value) {
    clinicInviteConsent = value;
    clearMessages();
  }

  bool joinClinicInvite() {
    if (!clinicInviteConsent) {
      showError('Allow this verified clinic link before joining.');
      return false;
    }
    clinicInviteJoined = true;
    showNotice('Dr. Kavita Sharma follow-up joined.');
    return true;
  }

  void toggleClinicSharing(bool value) {
    clinicSharing = value;
    showNotice(
      value
          ? 'Sharing is on for this follow-up case.'
          : 'Sharing is paused. Your private records remain saved.',
    );
  }

  void uploadFollowUpReport() {
    followUpReportUploaded = true;
    showNotice('Report uploaded to this follow-up case.');
  }

  void toggleMedicineReminder() {
    medicineReminder = !medicineReminder;
    showNotice(
      medicineReminder
          ? 'Medicine reminder set.'
          : 'Medicine reminder turned off.',
    );
  }

  void prepareSalon() {
    clearMessages();
  }

  void chooseSalonService(String value) {
    salonService = value;
    salonAmount = switch (value) {
      'Haircut' => 199,
      'Beard' => 120,
      'Facial' => 499,
      'Colour' => 799,
      'Massage' => 599,
      'Bridal' => 2499,
      _ => 199,
    };
    showNotice('$value selected. Price updated.');
  }

  void chooseSalonMode(SalonMode value) {
    salonMode = value;
    showNotice('${value.label} selected.');
  }

  void chooseSalonPayment(SalonPayment value) {
    salonPayment = value;
    showNotice('${value.label} selected.');
  }

  void chooseSalonAddon(String value) {
    salonAddon = value;
    showNotice('$value selected. Total ₹$salonTotal.');
  }

  Future<bool> confirmSalon() async {
    if (busy) return false;
    if (salonBooking != null) {
      showNotice('Booking ${salonBooking!.id} is already confirmed.');
      return true;
    }
    busy = true;
    clearMessages();
    try {
      salonBooking = await gateway.confirmSalonBooking(
        service: salonService,
        mode: salonMode,
        amount: salonTotal,
      );
      noticeMessage =
          'Slot ${salonBooking!.id} confirmed for today at 5:40 PM.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'The salon slot could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void cancelSalon() {
    salonBooking = null;
    salonCheckedIn = false;
    salonServiceDone = false;
    salonPaid = false;
    showNotice('Salon booking cancelled within the free window.');
  }

  void checkInSalon() {
    salonCheckedIn = true;
    showNotice('Royal Touch Salon acknowledged your arrival.');
  }

  void completeSalonService() {
    salonServiceDone = true;
    showNotice('Service marked complete. Review the final bill before paying.');
  }

  Future<bool> paySalonBill() async {
    if (busy || salonBooking == null) return false;
    if (salonPaid) {
      showNotice('Bill ${salonBooking!.id} is already paid.');
      return true;
    }
    busy = true;
    clearMessages();
    try {
      await gateway.paySalon(
        bookingId: salonBooking!.id,
        amount: salonTotal,
        method: salonPayment,
      );
      salonPaid = true;
      noticeMessage = 'Payment confirmed. Bill ${salonBooking!.id} is saved.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'Payment status could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setSalonRating(int value) {
    salonRating = value;
    notifyListeners();
  }

  bool submitSalonRating() {
    if (salonRating == 0) {
      showError('Choose a salon rating before submitting.');
      return false;
    }
    showNotice('Rating submitted. Your saved preference is ready.');
    return true;
  }

  void chooseSalonIssue(SalonIssue value) {
    salonIssue = value;
    clearMessages();
  }

  Future<bool> submitSalonSupport(String detail) async {
    if (busy || salonBooking == null) return false;
    if (salonSupportCase != null) {
      showNotice('Support case ${salonSupportCase!.id} is already open.');
      return true;
    }
    final resolved = detail.trim().isEmpty ? salonIssue.label : detail.trim();
    busy = true;
    clearMessages();
    try {
      salonSupportCase = await gateway.createSupportCase(
        subjectId: salonBooking!.id,
        reason: resolved,
      );
      noticeMessage =
          'Support case ${salonSupportCase!.id} created with the saved bill.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'Support could not be opened. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void prepareTask() {
    clearMessages();
  }

  void chooseTaskCity(String value) {
    taskCity = value;
    showNotice('$value selected for this task.');
  }

  void chooseTaskType(TaskType value) {
    taskType = value;
    showNotice('${value.label} selected.');
  }

  bool saveTaskDetail(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 12) {
      showError(
        'Add the exact place and instruction in at least 12 characters.',
      );
      return false;
    }
    taskDetail = trimmed;
    showNotice('Task detail saved.');
    return true;
  }

  void chooseTaskPayment(TaskPayment value) {
    taskPayment = value;
    showNotice('${value.label} selected.');
  }

  Future<bool> confirmTask() async {
    if (busy) return false;
    if (taskDetail.length < 12) {
      showError('Add the exact task detail before creating a payment hold.');
      return false;
    }
    if (task != null) {
      showNotice('Task ${task!.id} is already active.');
      return true;
    }
    busy = true;
    clearMessages();
    try {
      task = await gateway.createTask(
        type: taskType,
        city: taskCity,
        detail: taskDetail,
        heldAmount: taskHeldAmount,
      );
      noticeMessage =
          'Ramesh accepted ${task!.id}. ₹$taskHeldAmount is protected.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'The task could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void receiveTaskProof() {
    taskProofReceived = true;
    showNotice('Photo proof and the ₹420 counter bill are ready to review.');
  }

  void askForClearerProof() {
    taskProofReceived = false;
    showNotice('Ramesh has been asked for clearer proof. Payment stays held.');
  }

  Future<bool> releaseTaskPayment() async {
    if (busy || task == null || !taskProofReceived) {
      showError('Review the required proof before releasing payment.');
      return false;
    }
    if (taskReleased) {
      showNotice('₹$taskReleaseAmount was already released once.');
      return true;
    }
    busy = true;
    clearMessages();
    try {
      await gateway.releaseTaskPayment(
        taskId: task!.id,
        amount: taskReleaseAmount,
      );
      taskReleased = true;
      noticeMessage =
          '₹$taskReleaseAmount released. ₹$taskReturnAmount returned to you.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'Payment release could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setTaskRating(int value) {
    taskRating = value;
    notifyListeners();
  }

  void saveHelper() {
    helperSaved = true;
    showNotice('Ramesh saved for future tasks.');
  }

  void chooseTaskIssue(TaskIssue value) {
    taskIssue = value;
    clearMessages();
  }

  Future<bool> submitTaskSupport(String detail) async {
    if (busy || task == null) return false;
    if (taskSupportCase != null) {
      showNotice('Case ${taskSupportCase!.id} is already active.');
      return true;
    }
    final resolved = detail.trim().isEmpty ? taskIssue.label : detail.trim();
    busy = true;
    clearMessages();
    try {
      taskSupportCase = await gateway.createSupportCase(
        subjectId: task!.id,
        reason: resolved,
      );
      noticeMessage =
          'Case ${taskSupportCase!.id} created. ₹$taskHeldAmount remains protected.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'The support case could not be created. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void chooseTaskResolution(TaskResolution value) {
    taskResolution = value;
    showNotice('${value.label} selected. Review before confirming.');
  }

  Future<bool> acceptTaskResolution() async {
    if (busy || taskSupportCase == null) return false;
    if (resolutionComplete) {
      showNotice('This case resolution is already saved.');
      return true;
    }
    busy = true;
    clearMessages();
    try {
      await gateway.acceptResolution(
        caseId: taskSupportCase!.id,
        resolution: taskResolution,
      );
      resolutionComplete = true;
      noticeMessage =
          '${taskResolution.label} confirmed. The case record is saved.';
      return true;
    } on BookServiceException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } on Object {
      errorMessage = 'The resolution could not be confirmed. Try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void resetSalon() {
    salonBooking = null;
    salonCheckedIn = false;
    salonServiceDone = false;
    salonPaid = false;
    salonRating = 0;
    salonSupportCase = null;
    salonAddon = 'No add-on';
    clearMessages();
  }

  void resetTask() {
    task = null;
    taskProofReceived = false;
    taskReleased = false;
    taskRating = 0;
    helperSaved = false;
    taskSupportCase = null;
    resolutionComplete = false;
    clearMessages();
  }
}
