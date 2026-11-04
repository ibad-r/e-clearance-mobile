import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/date_format.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';

class NewClearanceScreen extends StatefulWidget {
  const NewClearanceScreen({super.key});

  @override
  State<NewClearanceScreen> createState() => _NewClearanceScreenState();
}

class _NewClearanceScreenState extends State<NewClearanceScreen> {
  static const _reasons = [
    'Contract Completion',
    'Resignation',
    'Retirement',
    'Transfer',
    'Other',
  ];

  static const _inputStyle = TextStyle(fontSize: 14, color: AppTheme.textDark);
  static const _hintStyle = TextStyle(fontSize: 14, color: Color(0xFF94A3B8));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _date;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _remarks;

  @override
  void initState() {
    super.initState();
    // Load saved values, so nothing is lost when coming back to this screen.
    final d = context.read<AppState>().draft;
    _date = TextEditingController(
        text: d.lastWorkingDay == null ? '' : formatShortDate(d.lastWorkingDay!));
    _phone = TextEditingController(text: d.phone);
    _address = TextEditingController(text: d.forwardingAddress);
    _remarks = TextEditingController(text: d.remarks);
  }

  @override
  void dispose() {
    _date.dispose();
    _phone.dispose();
    _address.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final draft = context.read<AppState>().draft;
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.lastWorkingDay ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      draft.lastWorkingDay = picked;
      _date.text = formatShortDate(picked);
    }
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushNamed(context, AppRoutes.review);
  }

  // Optional field: empty is fine, but if typed it must look like a phone.
  String? _validatePhone(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9 ]{10,15}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _deco(
      String hint, {
        IconData? prefix,
        IconData? suffix,
        double vertical = 14,
      }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
      border: _border(AppTheme.border),
      enabledBorder: _border(AppTheme.border),
      focusedBorder: _border(AppTheme.primary, width: 1.5),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red, width: 1.5),
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, size: 16, color: AppTheme.textMuted),
      prefixIconConstraints:
      const BoxConstraints(minWidth: 42, minHeight: 20),
      suffixIcon: suffix == null
          ? null
          : Icon(suffix, size: 16, color: AppTheme.textDark),
      suffixIconConstraints:
      const BoxConstraints(minWidth: 42, minHeight: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final emp = state.employee;
    final draft = state.draft;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 8,
        iconTheme: const IconThemeData(color: AppTheme.textDark, size: 22),
        title: const Text(
          'New Clearance Request',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1 of 2 · Details we already know are pre-filled and '
                    'locked.',
                style: TextStyle(
                    fontSize: 12.5, height: 1.4, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 18),
              const _Section('EMPLOYEE INFORMATION'),
              _LockedField('Employee Number', emp?.id ?? ''),
              _LockedField('Name', emp?.name ?? ''),
              _LockedField('Designation', emp?.designation ?? ''),
              _LockedField('Department', emp?.department ?? ''),
              _LockedField('Joining Date', emp?.joiningDate ?? ''),
              const SizedBox(height: 10),
              const _Section('LEAVING DETAILS'),
              const _Label('Last Working Day'),
              TextFormField(
                controller: _date,
                readOnly: true,
                onTap: _pickDate,
                style: _inputStyle,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please choose your last working day'
                    : null,
                decoration: _deco('Select date',
                    prefix: Icons.calendar_today_outlined,
                    suffix: Icons.calendar_today_outlined),
              ),
              const _Helper('Pick or confirm the date your service ends.'),
              const SizedBox(height: 16),
              const _Label('Reason for Leaving'),
              DropdownButtonFormField<String>(
                initialValue: draft.reason,
                isExpanded: true,
                icon: const SizedBox.shrink(),
                style: _inputStyle,
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => draft.reason = v,
                validator: (v) => v == null ? 'Please select a reason' : null,
                decoration: _deco('Select reason', vertical: 12),
              ),
              const SizedBox(height: 16),
              const _Label('Contact Number'),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: _inputStyle,
                onChanged: (v) => draft.phone = v,
                validator: _validatePhone,
                decoration:
                _deco('+92 300 0000142', prefix: Icons.phone_outlined),
              ),
              const _Helper('Optional. Used only for clearance follow-up.'),
              const SizedBox(height: 16),
              const _Label('Forwarding Address'),
              TextFormField(
                controller: _address,
                textInputAction: TextInputAction.next,
                style: _inputStyle,
                onChanged: (v) => draft.forwardingAddress = v,
                decoration: _deco('Optional'),
              ),
              const _Helper('Optional. Where final documents can be sent.'),
              const SizedBox(height: 16),
              const _Label('Remarks', suffix: '(optional)'),
              TextFormField(
                controller: _remarks,
                minLines: 3,
                maxLines: 3,
                maxLength: 250,
                style: _inputStyle,
                onChanged: (v) => draft.remarks = v,
                decoration: _deco('Anything the approver should know',
                    vertical: 18)
                    .copyWith(counterText: ''),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _continue,
                      child: const Text('Continue',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppTheme.textMuted,
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  final String? suffix;
  const _Label(this.text, {this.suffix});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark),
        children: [
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: const TextStyle(
                  fontWeight: FontWeight.w400, color: AppTheme.textMuted),
            ),
        ],
      ),
    ),
  );
}

class _Helper extends StatelessWidget {
  final String text;
  const _Helper(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
    ),
  );
}

class _LockedField extends StatelessWidget {
  final String label;
  final String value;
  const _LockedField(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EDF3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textDark)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}