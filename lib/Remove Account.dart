import 'package:flutter/material.dart';
import 'package:p2/logic/account_removal_logic.dart';
import 'package:p2/security/error_handler.dart';

class RemoveAccountPage extends StatefulWidget {
  const RemoveAccountPage({super.key});

  @override
  State<RemoveAccountPage> createState() => _RemoveAccountPageState();
}

class _RemoveAccountPageState extends State<RemoveAccountPage> {
  bool _isLoading = false;
  bool _showVerification = false;
  String? _errorMessage;
  final TextEditingController _verificationController = TextEditingController();
  List<String> _removalConsequences = [];
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _loadRemovalConsequences();
  }

  Future<void> _loadRemovalConsequences() async {
    try {
      final consequences = await AccountRemovalLogic.getRemovalConsequences();
      
      setState(() {
        _removalConsequences = [
          if (consequences['data_deleted'] == true) 
            "• All personal data will be permanently deleted",
          if (consequences['transactions_lost'] == true) 
            "• All transaction history will be lost",
          if (consequences['cannot_undo'] == true) 
            "• This action cannot be undone",
          if (consequences['timeframe'] != null) 
            "• Account will be fully removed within ${consequences['timeframe']}",
          "• You will lose access to all services and features",
          "• Any pending payments will be forfeited",
          "• Your reviews and ratings will be removed",
        ];
      });
    } catch (error) {
      ErrorHandler.logError('Load Removal Consequences', error);
    }
  }

  Future<void> _initiateAccountRemoval() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final validationResult = await AccountRemovalLogic.validateAccountRemoval();
      if (!validationResult) {
        setState(() {
          _errorMessage = AccountRemovalLogic.getValidationErrorMessage();
          _isLoading = false;
        });
        return;
      }

      final removalResult = await AccountRemovalLogic.initiateAccountRemoval();
      if (removalResult) {
        setState(() {
          _showVerification = true;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AccountRemovalLogic.getSuccessMessage()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        setState(() {
          _errorMessage = AccountRemovalLogic.getErrorMessage();
          _isLoading = false;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Initiate Account Removal', error);
      setState(() {
        _errorMessage = ErrorHandler.getSafeError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAccountRemoval() async {
    try {
      if (!_agreedToTerms) {
        setState(() {
          _errorMessage = "You must agree to the terms before proceeding";
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final code = _verificationController.text.trim();
      final confirmationResult = await AccountRemovalLogic.confirmAccountRemoval(code);
      
      if (confirmationResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AccountRemovalLogic.getConfirmationMessage()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          
          
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } else {
        setState(() {
          _errorMessage = AccountRemovalLogic.getVerificationErrorMessage();
          _isLoading = false;
        });
      }
    } catch (error) {
      ErrorHandler.logError('Confirm Account Removal', error);
      setState(() {
        _errorMessage = ErrorHandler.getSafeError(error);
        _isLoading = false;
      });
    }
  }

  void _showDetailedWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 10),
            Text("Final Warning"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AccountRemovalLogic.getRemovalWarning(),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ..._removalConsequences.map((consequence) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(consequence, style: const TextStyle(fontSize: 12)),
                )
              ).toList(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                      Navigator.pop(context);
                      _initiateAccountRemoval();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I understand the consequences and want to proceed",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Column(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 80,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        Text(
          AccountRemovalLogic.getRemovalWarning().split('\n\n')[0],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildConsequencesList() {
    if (_removalConsequences.isEmpty) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Consequences of account removal:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ..._removalConsequences.map((consequence) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                consequence,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            )
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Enter verification code",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "We've sent a 6-digit code to your email",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _verificationController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: "000000",
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    if (_errorMessage == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_showVerification) {
      return Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.red,
              disabledBackgroundColor: Colors.red.shade300,
            ),
            onPressed: _isLoading ? null : _confirmAccountRemoval,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Confirm Removal",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _showVerification = false;
                _verificationController.clear();
              });
            },
            child: const Text(
              "Cancel",
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.red,
            ),
            onPressed: _isLoading ? null : _showDetailedWarning,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Remove Account",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.grey[600],
            ),
            onPressed: _isLoading ? null : () {
              Navigator.pop(context);
            },
            child: const Text(
              "Cancel",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F0F46), Color(0xFF8A005D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.grey[700],
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWarningSection(),
                    _buildConsequencesList(),
                    if (_showVerification) _buildVerificationSection(),
                    _buildErrorDisplay(),
                    const SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _verificationController.dispose();
    super.dispose();
  }
}
