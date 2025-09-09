import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('mn'),
  ];

  // Navigation
  String get dashboard => locale.languageCode == 'mn' ? 'Хяналтын самбар' : 'Dashboard';
  String get transactions => locale.languageCode == 'mn' ? 'Гүйлгээ' : 'Transactions';
  String get loans => locale.languageCode == 'mn' ? 'Зээл' : 'Loans';
  String get settings => locale.languageCode == 'mn' ? 'Тохиргоо' : 'Settings';

  // Common actions
  String get add => locale.languageCode == 'mn' ? 'Нэмэх' : 'Add';
  String get edit => locale.languageCode == 'mn' ? 'Засах' : 'Edit';
  String get delete => locale.languageCode == 'mn' ? 'Устгах' : 'Delete';
  String get save => locale.languageCode == 'mn' ? 'Хадгалах' : 'Save';
  String get cancel => locale.languageCode == 'mn' ? 'Цуцлах' : 'Cancel';
  String get ok => locale.languageCode == 'mn' ? 'За' : 'OK';
  String get confirm => locale.languageCode == 'mn' ? 'Баталгаажуулах' : 'Confirm';

  // Dashboard
  String get myFinance => locale.languageCode == 'mn' ? 'Миний санхүү' : 'My Finance';
  String get totalBalance => locale.languageCode == 'mn' ? 'Нийт үлдэгдэл' : 'Total Balance';
  String get thisMonth => locale.languageCode == 'mn' ? 'Энэ сар' : 'This Month';
  String get addIncome => locale.languageCode == 'mn' ? 'Орлого нэмэх' : 'Add Income';
  String get addExpense => locale.languageCode == 'mn' ? 'Зардал нэмэх' : 'Add Expense';
  String get viewAll => locale.languageCode == 'mn' ? 'Бүгдийг харах' : 'View All';
  String get income => locale.languageCode == 'mn' ? 'Орлого' : 'Income';
  String get expenses => locale.languageCode == 'mn' ? 'Зардал' : 'Expenses';
  String get recentTransactions => locale.languageCode == 'mn' ? 'Сүүлийн гүйлгээ' : 'Recent Transactions';
  String get loanOverview => locale.languageCode == 'mn' ? 'Зээлийн тойм' : 'Loan Overview';

  // Transactions
  String get addTransaction => locale.languageCode == 'mn' ? 'Гүйлгээ нэмэх' : 'Add Transaction';
  String get editTransaction => locale.languageCode == 'mn' ? 'Гүйлгээ засах' : 'Edit Transaction';
  String get deleteTransaction => locale.languageCode == 'mn' ? 'Гүйлгээ устгах' : 'Delete Transaction';
  String get noTransactionsYet => locale.languageCode == 'mn' ? 'Одоохондоо гүйлгээ байхгүй байна' : 'No transactions yet';
  String get tapToAddFirst => locale.languageCode == 'mn' ? '+ дарж эхний гүйлгээгээ нэмнэ үү' : 'Tap + to add your first transaction';
  String get amount => locale.languageCode == 'mn' ? 'Дүн' : 'Amount';
  String get category => locale.languageCode == 'mn' ? 'Ангилал' : 'Category';
  String get date => locale.languageCode == 'mn' ? 'Огноо' : 'Date';
  String get note => locale.languageCode == 'mn' ? 'Тэмдэглэл' : 'Note';
  String get noteOptional => locale.languageCode == 'mn' ? 'Тэмдэглэл (заавал биш)' : 'Note (optional)';
  String get currency => locale.languageCode == 'mn' ? 'Валют' : 'Currency';
  String get expense => locale.languageCode == 'mn' ? 'Зардал' : 'Expense';

  // Loans
  String get addLoan => locale.languageCode == 'mn' ? 'Зээл нэмэх' : 'Add Loan';
  String get editLoan => locale.languageCode == 'mn' ? 'Зээл засах' : 'Edit Loan';
  String get deleteLoan => locale.languageCode == 'mn' ? 'Зээл устгах' : 'Delete Loan';
  String get loanName => locale.languageCode == 'mn' ? 'Зээлийн нэр' : 'Loan Name';
  String get principalAmount => locale.languageCode == 'mn' ? 'Үндсэн дүн' : 'Principal Amount';
  String get monthlyPayment => locale.languageCode == 'mn' ? 'Сарын төлбөр' : 'Monthly Payment';
  String get interestRate => locale.languageCode == 'mn' ? 'Хүүгийн хувь' : 'Interest Rate';
  String get startDate => locale.languageCode == 'mn' ? 'Эхлэх огноо' : 'Start Date';
  String get endDate => locale.languageCode == 'mn' ? 'Дуусах огноо' : 'End Date';
  String get hasEndDate => locale.languageCode == 'mn' ? 'Дуусах огнотой' : 'Has End Date';
  String get remainingBalance => locale.languageCode == 'mn' ? 'Үлдэгдэл' : 'Remaining Balance';
  String get progress => locale.languageCode == 'mn' ? 'Явц' : 'Progress';
  String get activeLoans => locale.languageCode == 'mn' ? 'Идэвхтэй зээл' : 'Active Loans';
  String get noActiveLoans => locale.languageCode == 'mn' ? 'Идэвхтэй зээл байхгүй' : 'No active loans';
  String get noLoansFound => locale.languageCode == 'mn' ? 'Зээл олдсонгүй' : 'No loans found';
  String get overdue => locale.languageCode == 'mn' ? 'Хугацаа хэтэрсэн' : 'Overdue';
  String get dueSoon => locale.languageCode == 'mn' ? 'Удахгүй хугацаа дуусах' : 'Due Soon';
  String get completed => locale.languageCode == 'mn' ? 'Дууссан' : 'Completed';
  String get active => locale.languageCode == 'mn' ? 'Идэвхтэй' : 'Active';
  String get all => locale.languageCode == 'mn' ? 'Бүгд' : 'All';

  // Payments
  String get addPayment => locale.languageCode == 'mn' ? 'Төлбөр нэмэх' : 'Add Payment';
  String get editPayment => locale.languageCode == 'mn' ? 'Төлбөр засах' : 'Edit Payment';
  String get deletePayment => locale.languageCode == 'mn' ? 'Төлбөр устгах' : 'Delete Payment';
  String get paymentAmount => locale.languageCode == 'mn' ? 'Төлбөрийн дүн' : 'Payment Amount';
  String get paymentDate => locale.languageCode == 'mn' ? 'Төлбөрийн огноо' : 'Payment Date';
  String get paymentHistory => locale.languageCode == 'mn' ? 'Төлбөрийн түүх' : 'Payment History';
  String get noPaymentsYet => locale.languageCode == 'mn' ? 'Одоохондоо төлбөр байхгүй байна' : 'No payments recorded yet';
  String get useMonthlyPayment => locale.languageCode == 'mn' ? 'Сарын төлбөр ашиглах' : 'Use Monthly Payment';
  String get payOffLoan => locale.languageCode == 'mn' ? 'Зээлийг бүтэн төлөх' : 'Pay Off Loan';

  // Settings
  String get exportAndBackup => locale.languageCode == 'mn' ? 'Экспорт ба нөөцлөх' : 'Export & Backup';
  String get defaultCurrency => locale.languageCode == 'mn' ? 'Үндсэн валют' : 'Default Currency';
  String get defaultExportFormat => locale.languageCode == 'mn' ? 'Үндсэн экспорт формат' : 'Default Export Format';
  String get fileNamingScheme => locale.languageCode == 'mn' ? 'Файлын нэрлэх схем' : 'File Naming Scheme';
  String get autoBackup => locale.languageCode == 'mn' ? 'Автомат нөөцлөх' : 'Auto Backup';
  String get exportData => locale.languageCode == 'mn' ? 'Өгөгдөл экспортлох' : 'Export Data';
  String get importData => locale.languageCode == 'mn' ? 'Өгөгдөл импортлох' : 'Import Data';
  String get notifications => locale.languageCode == 'mn' ? 'Мэдэгдэл' : 'Notifications';
  String get enableNotifications => locale.languageCode == 'mn' ? 'Мэдэгдэл идэвхжүүлэх' : 'Enable Notifications';
  String get reminderDaysBefore => locale.languageCode == 'mn' ? 'Хэдэн өдрийн өмнө сануулах' : 'Reminder Days Before Due Date';
  String get googleDriveSync => locale.languageCode == 'mn' ? 'Google Drive синк' : 'Google Drive Sync';
  String get driveSyncStatus => locale.languageCode == 'mn' ? 'Drive синкийн статус' : 'Drive Sync Status';
  String get connected => locale.languageCode == 'mn' ? 'Холбогдсон' : 'Connected';
  String get notConfigured => locale.languageCode == 'mn' ? 'Тохируулагдаагүй' : 'Not configured';
  String get lastSync => locale.languageCode == 'mn' ? 'Сүүлийн синк' : 'Last sync';
  String get configureDrive => locale.languageCode == 'mn' ? 'Drive тохируулах' : 'Configure Drive';
  String get reconfigure => locale.languageCode == 'mn' ? 'Дахин тохируулах' : 'Reconfigure';
  String get syncNow => locale.languageCode == 'mn' ? 'Одоо синк хийх' : 'Sync Now';
  String get dataManagement => locale.languageCode == 'mn' ? 'Өгөгдлийн удирдлага' : 'Data Management';
  String get clearAllData => locale.languageCode == 'mn' ? 'Бүх өгөгдөл арилгах' : 'Clear All Data';
  String get about => locale.languageCode == 'mn' ? 'Тухай' : 'About';
  String get version => locale.languageCode == 'mn' ? 'Хувилбар' : 'Version';

  // Filters
  String get filters => locale.languageCode == 'mn' ? 'Шүүлтүүр' : 'Filters';
  String get type => locale.languageCode == 'mn' ? 'Төрөл' : 'Type';
  String get allTypes => locale.languageCode == 'mn' ? 'Бүх төрөл' : 'All Types';
  String get allCategories => locale.languageCode == 'mn' ? 'Бүх ангилал' : 'All Categories';
  String get fromDate => locale.languageCode == 'mn' ? 'Эхлэх огноо' : 'From Date';
  String get toDate => locale.languageCode == 'mn' ? 'Дуусах огноо' : 'To Date';
  String get selectDate => locale.languageCode == 'mn' ? 'Огноо сонгох' : 'Select date';
  String get clearFilters => locale.languageCode == 'mn' ? 'Шүүлтүүр арилгах' : 'Clear Filters';
  String get search => locale.languageCode == 'mn' ? 'Хайх' : 'Search';

  // Form validation
  String get pleaseEnterAmount => locale.languageCode == 'mn' ? 'Дүн оруулна уу' : 'Please enter an amount';
  String get pleaseEnterValidNumber => locale.languageCode == 'mn' ? 'Зөв тоо оруулна уу' : 'Please enter a valid number';
  String get amountMustBeGreaterThanZero => locale.languageCode == 'mn' ? 'Дүн 0-с их байх ёстой' : 'Amount must be greater than 0';
  String get pleaseEnterCategory => locale.languageCode == 'mn' ? 'Ангилал оруулна уу' : 'Please enter a category';
  String get pleaseEnterLoanName => locale.languageCode == 'mn' ? 'Зээлийн нэр оруулна уу' : 'Please enter a loan name';

  // Confirmation dialogs
  String get areYouSureDeleteTransaction => locale.languageCode == 'mn' 
    ? 'Энэ гүйлгээг устгахдаа итгэлтэй байна уу?' 
    : 'Are you sure you want to delete this transaction?';
  String get areYouSureDeleteLoan => locale.languageCode == 'mn' 
    ? 'Энэ зээлийг устгахдаа итгэлтэй байна уу? Холбогдох бүх төлбөр мөн устгагдана.' 
    : 'Are you sure you want to delete this loan? This will also delete all associated payments.';
  String get areYouSureDeletePayment => locale.languageCode == 'mn' 
    ? 'Энэ төлбөрийг устгахдаа итгэлтэй байна уу?' 
    : 'Are you sure you want to delete this payment?';
  String get areYouSureClearAllData => locale.languageCode == 'mn' 
    ? 'Бүх өгөгдлийг арилгахдаа итгэлтэй байна уу? Энэ үйлдлийг буцаах боломжгүй.' 
    : 'Are you sure you want to clear all data? This action cannot be undone.';

  // Helper texts
  String get originalLoanAmount => locale.languageCode == 'mn' ? 'Анхны зээлийн дүн' : 'Original loan amount';
  String get expectedMonthlyPayment => locale.languageCode == 'mn' ? 'Хүлээгдэж буй сарын төлбөр' : 'Expected monthly payment amount';
  String get annualInterestRate => locale.languageCode == 'mn' ? 'Жилийн хүүгийн хувь (ж.нь 5.5)' : 'Annual interest rate (e.g. 5.5)';
  String get whenLoanStarted => locale.languageCode == 'mn' ? 'Зээл эхэлсэн огноо' : 'When the loan started';
  String get whenLoanShouldBePaid => locale.languageCode == 'mn' ? 'Зээлийг бүрэн төлөх ёстой огноо' : 'When the loan should be fully paid';
  String get specifyEndDate => locale.languageCode == 'mn' ? 'Зээлийг бүрэн төлөх огноог тодорхойлох' : 'Specify when the loan should be fully paid';
  String get enterPaymentAmount => locale.languageCode == 'mn' ? 'Төлбөрийн дүн оруулна уу' : 'Enter the payment amount';
  String get addNotesAboutPayment => locale.languageCode == 'mn' ? 'Энэ төлбөрийн тухай нэмэлт тэмдэглэл нэмэх' : 'Add any additional notes about this payment';
  String get useDateForCurrentDate => locale.languageCode == 'mn' ? '{date} ашиглан одоогийн огноо' : 'Use {date} for current date';

  // Status messages
  String get dataExportedSuccessfully => locale.languageCode == 'mn' ? 'Өгөгдөл амжилттай экспортлогдлоо!' : 'Data exported successfully!';
  String get failedToExportData => locale.languageCode == 'mn' ? 'Өгөгдөл экспортлоход алдаа гарлаа' : 'Failed to export data';
  String get loanNotFound => locale.languageCode == 'mn' ? 'Зээл олдсонгүй' : 'Loan not found';
  String get currentStatus => locale.languageCode == 'mn' ? 'Одоогийн төлөв' : 'Current Status';
  String get paymentProgress => locale.languageCode == 'mn' ? 'Төлбөрийн явц' : 'Payment Progress';
  String get paid => locale.languageCode == 'mn' ? 'Төлсөн' : 'Paid';
  String get edited => locale.languageCode == 'mn' ? 'Засагдсан' : 'Edited';

  // Numbers and time
  String get payments => locale.languageCode == 'mn' ? 'төлбөр' : 'payments';
  String get daysAgo => locale.languageCode == 'mn' ? 'өдрийн өмнө' : 'days ago';
  String get hoursAgo => locale.languageCode == 'mn' ? 'цагийн өмнө' : 'hours ago';
  String get minutesAgo => locale.languageCode == 'mn' ? 'минутын өмнө' : 'minutes ago';
  String get justNow => locale.languageCode == 'mn' ? 'Дөнгөж сая' : 'Just now';

  // Loan examples
  String get loanExamples => locale.languageCode == 'mn' 
    ? 'ж.нь: Машины зээл, Оюутны зээл, Орон сууцны зээл' 
    : 'e.g. Car Loan, Student Loan, Mortgage';

  // App description
  String get appDescription => locale.languageCode == 'mn' 
    ? 'Зээлийн удирдлагатай хувийн санхүүгийн хянагч' 
    : 'Personal finance tracker with loan management';

  // Export formats
  String get chooseExportFormat => locale.languageCode == 'mn' ? 'Экспорт формат сонгох:' : 'Choose export format:';
  
  // Additional dashboard translations
  String get loanDetails => locale.languageCode == 'mn' ? 'Зээлийн дэлгэрэнгүй' : 'Loan Details';
  String get totalDebt => locale.languageCode == 'mn' ? 'Нийт өр' : 'Total Debt';
  String get searchTransactions => locale.languageCode == 'mn' ? 'Гүйлгээ хайх' : 'Search Transactions';
  String get enterSearchTerm => locale.languageCode == 'mn' ? 'Хайх үгийг оруулна уу...' : 'Enter search term...';
  String get noResults => locale.languageCode == 'mn' ? 'Үр дүн олдсонгүй' : 'No results found';
  
  // Complete form field translations
  String get selectEndDate => locale.languageCode == 'mn' ? 'Дуусах огноо сонгох' : 'Select end date';
  String get thisActionCannotBeUndone => locale.languageCode == 'mn' ? 'Энэ үйлдлийг буцаах боломжгүй' : 'This action cannot be undone';
  String get paymentFor => locale.languageCode == 'mn' ? 'Төлбөр: ' : 'Payment for: ';
  String get loanFor => locale.languageCode == 'mn' ? 'Зээл: ' : 'Loan for: ';
  String get paymentCannotExceedBalance => locale.languageCode == 'mn' ? 'Төлбөр нь үлдэгдлээс их байж болохгүй' : 'Payment cannot exceed remaining balance';
  
  // Status and state translations
  String get remaining => locale.languageCode == 'mn' ? 'үлдэгдэл' : 'remaining';
  String get paymentSuccessful => locale.languageCode == 'mn' ? 'Төлбөр амжилттай' : 'Payment successful';
  String get loanCreated => locale.languageCode == 'mn' ? 'Зээл үүсгэгдлээ' : 'Loan created';
  String get transactionAdded => locale.languageCode == 'mn' ? 'Гүйлгээ нэмэгдлээ' : 'Transaction added';
  String get transactionUpdated => locale.languageCode == 'mn' ? 'Гүйлгээ шинэчлэгдлээ' : 'Transaction updated';
  String get loanUpdated => locale.languageCode == 'mn' ? 'Зээл шинэчлэгдлээ' : 'Loan updated';
  
  // More detailed field labels
  String get originalLoanAmountHint => locale.languageCode == 'mn' ? 'Анхны зээлийн дүн' : 'Original loan amount';
  String get expectedPaymentHint => locale.languageCode == 'mn' ? 'Хүлээгдэж буй сарын төлбөр' : 'Expected monthly payment amount';
  String get interestRateHint => locale.languageCode == 'mn' ? 'Жилийн хүүгийн хувь (ж.нь 5.5)' : 'Annual interest rate (e.g. 5.5)';
  String get whenLoanStartedHint => locale.languageCode == 'mn' ? 'Зээл эхэлсэн огноо' : 'When the loan started';
  String get whenLoanPaidHint => locale.languageCode == 'mn' ? 'Зээлийг бүрэн төлөх ёстой огноо' : 'When the loan should be fully paid';
  String get addPaymentNotesHint => locale.languageCode == 'mn' ? 'Энэ төлбөрийн тухай нэмэлт тэмдэглэл нэмэх' : 'Add any additional notes about this payment';
  
  // Settings page detailed translations
  String get automaticallyBackupData => locale.languageCode == 'mn' ? 'Өгөгдлийг автоматаар нөөцлөх' : 'Automatically backup data periodically';
  String get getNotifiedAboutLoans => locale.languageCode == 'mn' ? 'Зээлийн хугацаа дуусах тухай мэдэгдэл авах' : 'Get notified about loan due dates';
  String get connectedLastSync => locale.languageCode == 'mn' ? 'Холбогдсон - Сүүлийн синк:' : 'Connected - Last sync:';
  String get personalFinanceTracker => locale.languageCode == 'mn' ? 'Зээлийн удирдлагатай хувийн санхүүгийн хянагч' : 'Personal finance tracker with loan management';
  
  // Button and action translations
  String get viewAllTransactions => locale.languageCode == 'mn' ? 'Бүх гүйлгээг харах' : 'View All Transactions';
  String get viewAllLoans => locale.languageCode == 'mn' ? 'Бүх зээлийг харах' : 'View All Loans';
  String get addNewTransaction => locale.languageCode == 'mn' ? 'Шинэ гүйлгээ нэмэх' : 'Add New Transaction';
  String get addNewLoan => locale.languageCode == 'mn' ? 'Шинэ зээл нэмэх' : 'Add New Loan';
  String get makePayment => locale.languageCode == 'mn' ? 'Төлбөр хийх' : 'Make Payment';
  String get editLoanDetails => locale.languageCode == 'mn' ? 'Зээлийн мэдээлэл засах' : 'Edit Loan Details';
  
  // Time and date related
  String get today => locale.languageCode == 'mn' ? 'Өнөөдөр' : 'Today';
  String get yesterday => locale.languageCode == 'mn' ? 'Өчигдөр' : 'Yesterday';
  String get thisWeek => locale.languageCode == 'mn' ? 'Энэ долоо хоног' : 'This Week';
  String get lastWeek => locale.languageCode == 'mn' ? 'Өнгөрсөн долоо хоног' : 'Last Week';
  String get thisYear => locale.languageCode == 'mn' ? 'Энэ жил' : 'This Year';
  String get lastYear => locale.languageCode == 'mn' ? 'Өнгөрсөн жил' : 'Last Year';
  
  // Error messages
  String get errorExportingData => locale.languageCode == 'mn' ? 'Өгөгдөл экспортлоход алдаа гарлаа:' : 'Error exporting data:';
  String get errorLoadingData => locale.languageCode == 'mn' ? 'Өгөгдөл ачаалахад алдаа гарлаа' : 'Error loading data';
  String get errorSavingData => locale.languageCode == 'mn' ? 'Өгөгдөл хадгалахад алдаа гарлаа' : 'Error saving data';
  
  // Additional validation messages
  String get interestRateCannotBeNegative => locale.languageCode == 'mn' ? 'Хүүгийн хувь сөрөг байж болохгүй' : 'Interest rate cannot be negative';
  String get principalMustBePositive => locale.languageCode == 'mn' ? 'Үндсэн дүн эерэг байх ёстой' : 'Principal must be greater than 0';
  String get monthlyPaymentRequired => locale.languageCode == 'mn' ? 'Сарын төлбөр оруулах шаардлагатай' : 'Please enter the monthly payment';
  String get validNumberRequired => locale.languageCode == 'mn' ? 'Зөв тоо оруулна уу' : 'Please enter a valid number';
  
  // Summary and overview
  String get financialSummary => locale.languageCode == 'mn' ? 'Санхүүгийн хураангуй' : 'Financial Summary';
  String get monthlyOverview => locale.languageCode == 'mn' ? 'Сарын тойм' : 'Monthly Overview';
  String get yearlyOverview => locale.languageCode == 'mn' ? 'Жилийн тойм' : 'Yearly Overview';
  String get loanSummary => locale.languageCode == 'mn' ? 'Зээлийн хураангуй' : 'Loan Summary';
  
  // Additional loan specific terms
  String get principalAmountFull => locale.languageCode == 'mn' ? 'Үндсэн зээлийн дүн' : 'Principal Amount';
  String get monthlyPaymentFull => locale.languageCode == 'mn' ? 'Сарын төлбөрийн дүн' : 'Monthly Payment Amount';
  String get interestRateFull => locale.languageCode == 'mn' ? 'Жилийн хүүгийн хувь' : 'Annual Interest Rate';
  String get loanStartDate => locale.languageCode == 'mn' ? 'Зээл эхэлсэн огноо' : 'Loan Start Date';
  String get loanEndDate => locale.languageCode == 'mn' ? 'Зээл дуусах огноо' : 'Loan End Date';
  String get currentBalance => locale.languageCode == 'mn' ? 'Одоогийн үлдэгдэл' : 'Current Balance';
  String get totalPayments => locale.languageCode == 'mn' ? 'Нийт төлбөр' : 'Total Payments';
  String get remainingAmount => locale.languageCode == 'mn' ? 'Үлдэгдэл дүн' : 'Remaining Amount';
  
  // Categories
  String get selectCategory => locale.languageCode == 'mn' ? 'Ангилал сонгох' : 'Select Category';
  String get createCategory => locale.languageCode == 'mn' ? 'Ангилал үүсгэх' : 'Create Category';
  String get noCategory => locale.languageCode == 'mn' ? 'Ангилалгүй' : 'No Category';
  
  // Empty states
  String get noTransactionsFound => locale.languageCode == 'mn' ? 'Гүйлгээ олдсонгүй' : 'No transactions found';
  String get noPaymentsFound => locale.languageCode == 'mn' ? 'Төлбөр олдсонгүй' : 'No payments found';
  String get tapToAddFirstTransaction => locale.languageCode == 'mn' ? '+ товчийг дарж эхний гүйлгээгээ нэмнэ үү' : 'Tap + to add your first transaction';
  String get tapToAddFirstLoan => locale.languageCode == 'mn' ? '+ товчийг дарж эхний зээлээ нэмнэ үү' : 'Tap + to add your first loan';
  
  // Import/Export functionality
  String get selectFileToImport => locale.languageCode == 'mn' ? 'Импортлох файлаа сонгоно уу' : 'Select a file to import';
  String get supportedFormats => locale.languageCode == 'mn' ? 'Дэмжигдсэн форматууд:' : 'Supported formats:';
  String get fullBackup => locale.languageCode == 'mn' ? 'бүрэн нөөцлөлт' : 'full backup';
  String get individualData => locale.languageCode == 'mn' ? 'тусдаа өгөгдөл' : 'individual data';
  String get selectFile => locale.languageCode == 'mn' ? 'Файл сонгох' : 'Select File';
  String get importingData => locale.languageCode == 'mn' ? 'Өгөгдөл импортлож байна...' : 'Importing data...';
  String get importSuccess => locale.languageCode == 'mn' ? 'Импорт амжилттай боллоо' : 'Import Successful';
  String get importFailed => locale.languageCode == 'mn' ? 'Импорт амжилтгүй боллоо' : 'Import Failed';
  String get importError => locale.languageCode == 'mn' ? 'Импортын алдаа' : 'Import Error';
  String get importedItems => locale.languageCode == 'mn' ? 'Импортлогдсон зүйлс' : 'Imported Items';
  String get importWarnings => locale.languageCode == 'mn' ? 'Импортын анхааруулга' : 'Import Warnings';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}