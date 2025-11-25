import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late String _userEmail;
  String _tempImagePath = '';
  bool _isLoading = false;
  final bool isWeb = kIsWeb;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('current_user_email') ?? 'N/A';
      _nameController.text = prefs.getString('userName') ?? 'Pengguna';
      _addressController.text =
          prefs.getString('user_address') ?? 'Alamat belum diatur';
      _tempImagePath = prefs.getString('profile_image_path') ?? '';
    });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 55,
    );

    if (pickedFile != null) {
      setState(() {
        _tempImagePath = pickedFile.path;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library, color: darkPrimaryColor),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: darkPrimaryColor),
              title: const Text('Ambil Foto Baru'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userName', _nameController.text.trim());
      await prefs.setString('user_address', _addressController.text.trim());
      await prefs.setString('profile_image_path', _tempImagePath);

      final userBox = Hive.box<UserModel>('userBox');
      final userKey = userBox.keys.firstWhere(
        (key) => userBox.get(key)?.email == _userEmail,
        orElse: () => null,
      );

      if (userKey != null) {
        final existingUser = userBox.get(userKey);
        if (existingUser != null) {
          existingUser.username = _nameController.text.trim();
          await existingUser.save();
        }
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: darkPrimaryColor,
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEnabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        enabled: isEnabled,
        maxLines: maxLines,
        style: TextStyle(color: isEnabled ? darkPrimaryColor : Colors.grey),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: secondaryAccentColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: secondaryAccentColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: darkPrimaryColor, width: 2),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        validator: (value) {
          if (!isEnabled) return null;
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    bool showPlaceholderIcon = true;

    if (_tempImagePath.isNotEmpty) {
      if (isWeb) {
        imageProvider = NetworkImage(_tempImagePath);
        showPlaceholderIcon = false;
      } else if (File(_tempImagePath).existsSync()) {
        imageProvider = FileImage(File(_tempImagePath));
        showPlaceholderIcon = false;
      }
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white,
                    backgroundImage: imageProvider,
                    child: showPlaceholderIcon
                        ? Icon(Icons.person, size: 70, color: darkPrimaryColor)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: darkPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                icon: Icons.person,
              ),
              _buildTextField(
                controller: TextEditingController(text: _userEmail),
                label: 'Email (Tidak Dapat Diubah)',
                icon: Icons.email,
                isEnabled: false,
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Alamat Pengiriman',
                icon: Icons.location_on,
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPrimaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
