import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:p2/services/auth_service.dart'; 

class LogoutConfirmationPage extends StatefulWidget {
  const LogoutConfirmationPage({super.key});

  @override
  State<LogoutConfirmationPage> createState() => _LogoutConfirmationPageState();
}

class _LogoutConfirmationPageState extends State<LogoutConfirmationPage> {
  bool _isLoading = false;
  String _selectedOption = '';

  Future<void> _handleLogout(bool fromAllDevices) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Logout'),
        backgroundColor: const Color(0xFF1F0F46),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Confirm Logout',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F0F46),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select your preferred logout method',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // Logout from current device only
            GestureDetector(
              key: const ValueKey('logoutNormalOption'),
              onTap: () => _selectOption('normal'),
              child: Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: _selectedOption == 'normal' 
                      ? const Color(0xFF1F0F46).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedOption == 'normal' 
                        ? const Color(0xFF1F0F46)
                        : Colors.grey.shade300,
                    width: _selectedOption == 'normal' ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: _selectedOption == 'normal' 
                          ? const Color(0xFF1F0F46)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout from this device only',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedOption == 'normal' 
                                  ? const Color(0xFF1F0F46)
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'You will remain logged in on your other devices',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedOption == 'normal')
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),

            const Spacer(),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('logoutCancelButton'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    key: const ValueKey('logoutConfirmButton'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedOption.isEmpty
                          ? Colors.grey
                          : const Color(0xFF8A005D),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _selectedOption.isEmpty || _isLoading
                        ? null
                        : () => _handleLogout(_selectedOption == 'all'),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
