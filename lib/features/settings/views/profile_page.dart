import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/firebase_auth_repository.dart';
import '../models/app_user_model.dart';
import '../services/avatar_service.dart';

class ProfilePage extends StatefulWidget {
  final AppUserModel user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _authRepository = FirebaseAuthRepository();
  final _picker = ImagePicker();

  String? _localAvatarBase64;
  String? _tempSelectedBase64;
  Uint8List? _tempSelectedBytes;
  bool _isLoading = false;
  bool _hasCustomAvatar = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _loadCurrentAvatar();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAvatar() async {
    final local = await AvatarService.getLocalAvatar(widget.user.id);
    if (mounted) {
      setState(() {
        _localAvatarBase64 = local;
        _hasCustomAvatar = (local != null && local.isNotEmpty) ||
            (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _tempSelectedBytes = bytes;
        _tempSelectedBase64 = base64String;
        _hasCustomAvatar = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto carregada com sucesso! Clique em salvar para aplicar.'),
            backgroundColor: AppColors.win,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao acessar a câmera/galeria: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Alterar foto de perfil',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: cs.primary),
                ),
                title: const Text('Tirar nova foto (Câmera)'),
                subtitle: const Text('Use a câmera do seu dispositivo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.secondary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_outlined, color: cs.secondary),
                ),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Selecione uma imagem salva'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_hasCustomAvatar)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remover foto'),
                  subtitle: const Text('Voltar para o avatar padrão'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _tempSelectedBytes = null;
                      _tempSelectedBase64 = ''; // Empty string indicates removal
                      _hasCustomAvatar = false;
                    });
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authRepository.updateProfile(
        name: _nameController.text.trim(),
      );

      if (_tempSelectedBase64 != null) {
        if (_tempSelectedBase64!.isEmpty) {
          await AvatarService.clearLocalAvatar(widget.user.id);
        } else {
          await AvatarService.saveLocalAvatar(
            widget.user.id,
            _tempSelectedBase64!,
          );
        }

        if (mounted) {
          setState(() {
            _localAvatarBase64 =
                _tempSelectedBase64!.isEmpty ? null : _tempSelectedBase64;
            _tempSelectedBase64 = null;
            _tempSelectedBytes = null;
            _hasCustomAvatar = _localAvatarBase64 != null ||
                (widget.user.avatarUrl != null &&
                    widget.user.avatarUrl!.isNotEmpty);
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: AppColors.win,
          ),
        );
        Navigator.pop(context, true);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro inesperado ao salvar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel salvar a foto de perfil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Choose which image bytes to display (preview)
    ImageProvider? avatarImage;
    Widget? initialsFallback;

    if (_tempSelectedBytes != null) {
      avatarImage = MemoryImage(_tempSelectedBytes!);
    } else if (_tempSelectedBase64 == '') {
      // The user removed the image in the current session edit
      initialsFallback = _buildInitialsPlaceholder(cs);
    } else if (_localAvatarBase64 != null && _localAvatarBase64!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(_localAvatarBase64!));
      } catch (_) {
        initialsFallback = _buildInitialsPlaceholder(cs);
      }
    } else if (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(widget.user.avatarUrl!);
    } else {
      initialsFallback = _buildInitialsPlaceholder(cs);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Avatar stack with edit button
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: cs.primary.withOpacity(0.12),
                              backgroundImage: avatarImage,
                              child: avatarImage == null ? initialsFallback : null,
                            ),
                          ),
                        ),
                        // Circular edit button
                        Material(
                          color: cs.primary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _showImagePickerOptions,
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _showImagePickerOptions,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Alterar Foto de Perfil'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile info inputs
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    color: isDark ? cs.surfaceContainerHighest : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Informações da Conta',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                          ),
                          const SizedBox(height: 20),
                          // Name input
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Nome de exibição',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 3) {
                                return 'Informe um nome com pelo menos 3 letras.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Email input (read-only)
                          TextFormField(
                            initialValue: widget.user.email ?? 'Sem e-mail',
                            readOnly: true,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail (Não editável)',
                              prefixIcon: Icon(Icons.mail_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveProfile,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text(
                        'Salvar Alterações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsPlaceholder(ColorScheme cs) {
    final nameStr = _nameController.text.trim();
    String initials = 'U';
    
    if (nameStr.isNotEmpty) {
      final parts = nameStr.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        if (parts.length >= 2) {
          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else {
          initials = parts[0][0].toUpperCase();
        }
      }
    }

    return Text(
      initials,
      style: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.w900,
        fontSize: 48,
      ),
    );
  }
}
