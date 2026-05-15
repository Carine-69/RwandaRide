import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();

  String _role = 'rider';
  String _vehicleType = 'moto';
  bool _showPassword = false;

  static const _vehicleTypes = ['moto', 'economy', 'standard', 'xl'];
  static const _vehicleLabels = {
    'moto': 'Moto (200 RWF/km)',
    'economy': 'Economy (350 RWF/km)',
    'standard': 'Standard (500 RWF/km)',
    'xl': 'XL (700 RWF/km)',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      licenseNumber: _role == 'driver' ? _licenseController.text.trim() : null,
      vehicleType: _role == 'driver' ? _vehicleType : null,
      vehiclePlate: _role == 'driver' ? _plateController.text.trim() : null,
    );
    if (!mounted) return;
    if (!ok && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role selector
              const Text('I am a:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RoleChip(
                    label: 'Rider',
                    icon: Icons.person,
                    selected: _role == 'rider',
                    onTap: () => setState(() => _role = 'rider'),
                  ),
                  const SizedBox(width: 12),
                  _RoleChip(
                    label: 'Driver',
                    icon: Icons.drive_eta,
                    selected: _role == 'driver',
                    onTap: () => setState(() => _role = 'driver'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Common fields
              AppTextField(
                label: 'Full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone number',
                hint: '0788000000',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => v!.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Email (optional)',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: !_showPassword,
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Enter a password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),

              // Driver-only fields
              if (_role == 'driver') ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Driver Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),