import 'package:flutter/material.dart';

void main() {
  runApp(const SmartQApp());
}

// ==========================================
// DATA MODELS
// ==========================================
enum TokenStatus { waiting, serving, served, skipped, cancelled }

class Department {
  final String id;
  final String name;
  final String prefix;
  final String counterNumber;

  Department({
    required this.id,
    required this.name,
    required this.prefix,
    required this.counterNumber,
  });
}

class TokenModel {
  final String id;
  final int tokenNumber;
  final String formattedToken;
  final String userName;
  final String userPhone;
  final String departmentId;
  final String departmentName;
  final String counterNumber;
  TokenStatus status;
  final String bookedTime;
  final DateTime createdAt;

  TokenModel({
    required this.id,
    required this.tokenNumber,
    required this.formattedToken,
    required this.userName,
    required this.userPhone,
    required this.departmentId,
    required this.departmentName,
    required this.counterNumber,
    required this.status,
    required this.bookedTime,
    required this.createdAt,
  });
}

// ==========================================
// MAIN APP ROOT
// ==========================================
class SmartQApp extends StatelessWidget {
  const SmartQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart_q',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MainScreen(),
    );
  }
}

// ==========================================
// MAIN SCREEN WITH ROLE SWITCHING & NAVIGATION
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Global Roles: 'USER' | 'STAFF' | 'ADMIN'
  String _currentRole = 'USER';
  int _selectedTabIndex = 0;

  // Master Initial Data
  final List<Department> _departments = [
    Department(
      id: 'dept-1',
      name: 'General Enquiries',
      prefix: 'GEN',
      counterNumber: 'Counter 01',
    ),
    Department(
      id: 'dept-2',
      name: 'Accounts & Billing',
      prefix: 'ACC',
      counterNumber: 'Counter 02',
    ),
    Department(
      id: 'dept-3',
      name: 'Technical Support',
      prefix: 'SUP',
      counterNumber: 'Counter 03',
    ),
  ];

  late List<TokenModel> _tokens;
  String? _myActiveTokenId;

  // Form State for User Generation
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedDeptId = 'dept-1';

  // Staff State
  String _staffSelectedDeptId = 'dept-1';
  final _scanController = TextEditingController();
  TokenModel? _scannedToken;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    // Pre-populated initial mock data
    _tokens = [
      TokenModel(
        id: 'tkn-1',
        tokenNumber: 1,
        formattedToken: 'GEN-001',
        userName: 'Rajesh Kumar',
        userPhone: '+91 9876543210',
        departmentId: 'dept-1',
        departmentName: 'General Enquiries',
        counterNumber: 'Counter 01',
        status: TokenStatus.served,
        bookedTime: '09:30 AM',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TokenModel(
        id: 'tkn-2',
        tokenNumber: 2,
        formattedToken: 'GEN-002',
        userName: 'Priya Sharma',
        userPhone: '+91 9812345678',
        departmentId: 'dept-1',
        departmentName: 'General Enquiries',
        counterNumber: 'Counter 01',
        status: TokenStatus.serving,
        bookedTime: '10:15 AM',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      TokenModel(
        id: 'tkn-3',
        tokenNumber: 3,
        formattedToken: 'GEN-003',
        userName: 'Anil Verma',
        userPhone: '+91 9711223344',
        departmentId: 'dept-1',
        departmentName: 'General Enquiries',
        counterNumber: 'Counter 01',
        status: TokenStatus.waiting,
        bookedTime: '10:45 AM',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      TokenModel(
        id: 'tkn-4',
        tokenNumber: 1,
        formattedToken: 'ACC-001',
        userName: 'Suresh Patel',
        userPhone: '+91 9988776655',
        departmentId: 'dept-2',
        departmentName: 'Accounts & Billing',
        counterNumber: 'Counter 02',
        status: TokenStatus.serving,
        bookedTime: '10:00 AM',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];
    _myActiveTokenId = 'tkn-3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // Calculate People Ahead for a specific token
  int _getPeopleAhead(TokenModel token) {
    if (token.status != TokenStatus.waiting) return 0;
    return _tokens.where((t) {
      return t.departmentId == token.departmentId &&
          t.status == TokenStatus.waiting &&
          t.createdAt.isBefore(token.createdAt);
    }).length;
  }

  // Token Generation Handler
  void _generateToken() {
    if (!_formKey.currentState!.validate()) return;

    final targetDept = _departments.firstWhere((d) => d.id == _selectedDeptId);
    final deptTokens =
        _tokens.where((t) => t.departmentId == targetDept.id).toList();
    final nextNum = deptTokens.length + 1;
    final formattedNum =
        '${targetDept.prefix}-${nextNum.toString().padLeft(3, '0')}';

    final now = DateTime.now();
    final timeStr =
        '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final newToken = TokenModel(
      id: 'tkn-${now.millisecondsSinceEpoch}',
      tokenNumber: nextNum,
      formattedToken: formattedNum,
      userName: _nameController.text.trim(),
      userPhone: '+91 ${cleanPhone.substring(cleanPhone.length - 10)}',
      departmentId: targetDept.id,
      departmentName: targetDept.name,
      counterNumber: targetDept.counterNumber,
      status: TokenStatus.waiting,
      bookedTime: timeStr,
      createdAt: now,
    );

    setState(() {
      _tokens.add(newToken);
      _myActiveTokenId = newToken.id;
      _nameController.clear();
      _phoneController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token $formattedNum Generated Successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelToken(String tokenId) {
    setState(() {
      final token = _tokens.firstWhere((t) => t.id == tokenId);
      token.status = TokenStatus.cancelled;
    });
  }

  // Staff Controls
  void _callNext() {
    final waitingTokens = _tokens
        .where((t) =>
            t.departmentId == _staffSelectedDeptId &&
            t.status == TokenStatus.waiting)
        .toList();

    if (waitingTokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No waiting tokens in this queue.')),
      );
      return;
    }

    final nextToken = waitingTokens.first;

    setState(() {
      // Auto-complete previous serving token if any
      for (var t in _tokens) {
        if (t.departmentId == _staffSelectedDeptId &&
            t.status == TokenStatus.serving) {
          t.status = TokenStatus.served;
        }
      }
      nextToken.status = TokenStatus.serving;
    });
  }

  void _markServed(String tokenId) {
    setState(() {
      _tokens.firstWhere((t) => t.id == tokenId).status = TokenStatus.served;
    });
  }

  void _skipToken(String tokenId) {
    setState(() {
      _tokens.firstWhere((t) => t.id == tokenId).status = TokenStatus.skipped;
    });
  }

  void _lookupQR() {
    final input = _scanController.text.trim().toLowerCase();
    setState(() {
      _scanError = null;
      _scannedToken = null;
    });

    if (input.isEmpty) return;

    try {
      final found = _tokens.firstWhere(
        (t) =>
            t.formattedToken.toLowerCase() == input ||
            t.id.toLowerCase() == input,
      );
      setState(() {
        _scannedToken = found;
      });
    } catch (_) {
      setState(() {
        _scanError = 'Token not found in system record.';
      });
    }
  }

  // Role Switching Logic
  void _switchRole(String newRole) {
    setState(() {
      _currentRole = newRole;
      _selectedTabIndex = 0; // Reset tab view on role switch
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Dark Slate
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.confirmation_number,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Smart_q',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Role Switcher Segmented Control
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _roleButton('USER', 'User'),
                _roleButton('STAFF', 'Staff'),
                _roleButton('ADMIN', 'Admin'),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Navigation Tab Bar based on current Role
          // Dynamic Navigation Tab Bar based on current Role
Container(
  decoration: BoxDecoration(
    color: Colors.white, // Moved inside decoration
    border: const Border(
      bottom: BorderSide(color: Color(0xFFE2E8F0)),
    ),
  ), // Added a comma here
  child: Row(
              children: _getTabsForRole().asMap().entries.map((entry) {
                final idx = entry.key;
                final label = entry.value;
                final isSelected = _selectedTabIndex == idx;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical:14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Main View Content Body
          Expanded(child: _buildActiveTabBody()),
        ],
      ),
    );
  }

  Widget _roleButton(String roleKey, String label) {
    final isSelected = _currentRole == roleKey;
    return GestureDetector(
      onTap: () => _switchRole(roleKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<String> _getTabsForRole() {
    if (_currentRole == 'USER') {
      return ['User Portal', 'Live Queue Tab'];
    } else if (_currentRole == 'STAFF') {
      return ['Staff Control Station', 'Live Queue Tab'];
    } else {
      return ['Analytics Dashboard', 'Live Queue Tab'];
    }
  }

  Widget _buildActiveTabBody() {
    if (_currentRole == 'USER') {
      return _selectedTabIndex == 0
          ? _buildUserPortal()
          : _buildLiveQueueTab();
    } else if (_currentRole == 'STAFF') {
      return _selectedTabIndex == 0
          ? _buildStaffConsole()
          : _buildLiveQueueTab();
    } else {
      return _selectedTabIndex == 0
          ? _buildAdminAnalytics()
          : _buildLiveQueueTab();
    }
  }

  // ==========================================
  // ROLE: USER -> TAB 1: USER PORTAL
  // ==========================================
  Widget _buildUserPortal() {
    final activeToken = _tokens.firstWhere(
      (t) => t.id == _myActiveTokenId,
      orElse: () => _tokens.last,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Generate Token Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            color: Color(0xFF4F46E5)),
                        SizedBox(width: 8),
                        Text(
                          'Generate Token',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number (India) *',
                        hintText: '9876543210',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (val) {
                        if (val == null) return 'Enter mobile number';
                        final clean = val.replaceAll(RegExp(r'\D'), '');
                        if (clean.length < 10) {
                          return 'Enter valid 10-digit Indian phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Select Department / Counter',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: _departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept.id,
                          child: Text('${dept.name} (${dept.counterNumber})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDeptId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _generateToken,
                        icon: const Icon(Icons.add),
                        label: const Text('Generate Token',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Generated Token View
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACTIVE TOKEN',
                              style: TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            activeToken.formattedToken,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(activeToken.counterNumber),
                        backgroundColor: const Color(0xFF312E81),
                        labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Simulated QR Code Display
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomPaint(
                          painter: QRCodePainter(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${activeToken.id}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace'),
                      ),
                      const Divider(height: 24),
                      _infoRow('Ticket Holder Name', activeToken.userName),
                      _infoRow('Mobile Number', activeToken.userPhone),
                      _infoRow('Booked Time', activeToken.bookedTime),
                      _infoRow('Department', activeToken.departmentName),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_outline,
                                    color: Color(0xFF4F46E5), size: 18),
                                SizedBox(width: 8),
                                Text('People Ahead',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF312E81))),
                              ],
                            ),
                            Text(
                              '${_getPeopleAhead(activeToken)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4F46E5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(activeToken.status)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'STATUS: ${activeToken.status.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(activeToken.status),
                              ),
                            ),
                          ),
                          if (activeToken.status == TokenStatus.waiting)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () => _cancelToken(activeToken.id),
                              icon: const Icon(Icons.cancel_outlined, size: 14),
                              label: const Text('Cancel Token',
                                  style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  // ==========================================
  // TAB: LIVE QUEUE TAB (User, Staff & Admin)
  // ==========================================
  Widget _buildLiveQueueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Counter Status Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Department Status Cards
          Column(
            children: _departments.map((dept) {
              final servingToken = _tokens.firstWhere(
                (t) =>
                    t.departmentId == dept.id &&
                    t.status == TokenStatus.serving,
                orElse: () => TokenModel(
                  id: '',
                  tokenNumber: 0,
                  formattedToken: '---',
                  userName: '',
                  userPhone: '',
                  departmentId: '',
                  departmentName: '',
                  counterNumber: '',
                  status: TokenStatus.waiting,
                  bookedTime: '',
                  createdAt: DateTime.now(),
                ),
              );

              final waitingCount = _tokens
                  .where((t) =>
                      t.departmentId == dept.id &&
                      t.status == TokenStatus.waiting)
                  .length;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dept.counterNumber,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dept.name,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(
                              'Now Serving: ${servingToken.formattedToken}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$waitingCount Ahead',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text(
            'Waiting Tokens Queue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Waiting Tokens Table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Token No.')),
                  DataColumn(label: Text('Holder')),
                  DataColumn(label: Text('Counter')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _tokens.map((token) {
                  return DataRow(cells: [
                    DataCell(Text(token.formattedToken,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(token.userName)),
                    DataCell(Text(token.counterNumber)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(token.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          token.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(token.status),
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROLE: STAFF -> TAB 1: STAFF CONTROL STATION
  // ==========================================
  Widget _buildStaffConsole() {
    final activeServing = _tokens.firstWhere(
      (t) =>
          t.departmentId == _staffSelectedDeptId &&
          t.status == TokenStatus.serving,
      orElse: () => TokenModel(
        id: '',
        tokenNumber: 0,
        formattedToken: '',
        userName: '',
        userPhone: '',
        departmentId: '',
        departmentName: '',
        counterNumber: '',
        status: TokenStatus.waiting,
        bookedTime: '',
        createdAt: DateTime.now(),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Staff Station Counter
         DropdownButtonFormField<String>(
  value: _staffSelectedDeptId,
  decoration: const InputDecoration(
    labelText: 'Select Operator Counter Station',
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  ), // InputDecoration
  items: _departments.map((dept) {
    return DropdownMenuItem<String>(
      value: dept.id,
      child: Text('${dept.counterNumber} - ${dept.name}'),
    ); // DropdownMenuItem
  }).toList(),
  onChanged: (val) {
    if (val != null) {
      setState(() => _staffSelectedDeptId = val);
    }
  },
), 
          const SizedBox(height: 16),

          // Action Station Console
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: const Color(0xFF0F172A),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'CURRENTLY SERVING',
                    style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeServing.formattedToken.isNotEmpty
                        ? activeServing.formattedToken
                        : '---',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  if (activeServing.userName.isNotEmpty) ...[
                    Text(activeServing.userName,
                        style: const TextStyle(
                            color: Color(0xFFA5B4FC), fontSize: 13)),
                    Text(activeServing.userPhone,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 11)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _markServed(activeServing.id),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Mark Served',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _skipToken(activeServing.id),
                            icon: const Icon(Icons.skip_next, size: 16),
                            label: const Text('Skip',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _callNext,
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text('Call Next Customer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // QR Scanner Lookup Tool
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text('QR Lookup Tool',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scanController,
                          decoration: const InputDecoration(
                            hintText: 'Enter code (e.g. GEN-003 or tkn-3)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _lookupQR,
                        child: const Text('Lookup'),
                      ),
                    ],
                  ),
                  if (_scanError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_scanError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 11)),
                    ),
                  if (_scannedToken != null) ...[
                    const Divider(height: 20),
                    _infoRow(
                        'Token Code', _scannedToken!.formattedToken),
                    _infoRow('Name', _scannedToken!.userName),
                    _infoRow('Mobile', _scannedToken!.userPhone),
                    _infoRow('Department', _scannedToken!.departmentName),
                    _infoRow('Status', _scannedToken!.status.name.toUpperCase()),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROLE: ADMIN -> TAB 1: ANALYTICS DASHBOARD
  // ==========================================
 Widget _buildAdminAnalytics() {
    final totalIssued = _tokens.length;
    final totalServed =
        _tokens.where((t) => t.status == TokenStatus.served).length;
    final totalSkipped = _tokens
        .where((t) =>
            t.status == TokenStatus.skipped ||
            t.status == TokenStatus.cancelled)
        .length;
    final totalWaiting =
        _tokens.where((t) => t.status == TokenStatus.waiting).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Single Combined Analytics Box
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text(
                        'Performance Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _analyticStatItem(
                          title: 'Issued Today',
                          value: '$totalIssued',
                          icon: Icons.confirmation_number,
                          iconColor: const Color(0xFF4F46E5),
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: _analyticStatItem(
                          title: 'Served Count',
                          value: '$totalServed',
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: _analyticStatItem(
                          title: 'Skipped / Cancelled',
                          value: '$totalSkipped',
                          icon: Icons.cancel,
                          iconColor: Colors.red,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: _analyticStatItem(
                          title: 'Waiting Queue',
                          value: '$totalWaiting',
                          icon: Icons.people,
                          iconColor: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TokenStatus status) {
    switch (status) {
      case TokenStatus.waiting:
        return Colors.amber.shade800;
      case TokenStatus.serving:
        return Colors.green;
      case TokenStatus.served:
        return Colors.blue;
      case TokenStatus.skipped:
      case TokenStatus.cancelled:
        return Colors.red;
    }
  }
}

class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;

    canvas.drawRect(const Rect.fromLTWH(10, 10, 30, 30), paint);
    canvas.drawRect(
        const Rect.fromLTWH(15, 15, 20, 20), Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(20, 20, 10, 10), paint);

    canvas.drawRect(Rect.fromLTWH(size.width - 40, 10, 30, 30), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 35, 15, 20, 20),
        Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - 30, 20, 10, 10), paint);

    canvas.drawRect(Rect.fromLTWH(10, size.height - 40, 30, 30), paint);
    canvas.drawRect(Rect.fromLTWH(15, size.height - 35, 20, 20),
        Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(20, size.height - 30, 10, 10), paint);

    canvas.drawRect(const Rect.fromLTWH(50, 15, 10, 25), paint);
    canvas.drawRect(const Rect.fromLTWH(65, 20, 25, 8), paint);
    canvas.drawRect(const Rect.fromLTWH(15, 50, 25, 10), paint);
    canvas.drawRect(const Rect.fromLTWH(50, 50, 35, 35), paint);
    canvas.drawRect(
        const Rect.fromLTWH(58, 58, 18, 18), Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(62, 62, 10, 10), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 35, 50, 20, 10), paint);
    canvas.drawRect(Rect.fromLTWH(50, size.height - 35, 20, 20), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
