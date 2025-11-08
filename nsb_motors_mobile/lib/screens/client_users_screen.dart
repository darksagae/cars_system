import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class ClientUsersScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  const ClientUsersScreen({super.key, required this.clientId, required this.clientName});

  @override
  State<ClientUsersScreen> createState() => _ClientUsersScreenState();
}

class _ClientUsersScreenState extends State<ClientUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await SupabaseService.getClientUsers(widget.clientId);
    setState(() { _users = list; _loading = false; });
  }

  Future<void> _addUser() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showMessage('Enter username and password');
      return;
    }
    final hash = crypto.sha256.convert(utf8.encode(p)).toString();
    final ok = await SupabaseService.upsertClientUser(
      clientId: widget.clientId,
      username: u,
      passwordHash: hash,
      role: _role,
    );
    if (!mounted) return;
    if (ok) {
      _userCtrl.clear();
      _passCtrl.clear();
      await _load();
      ScaffoldMessenger.of(context).showMessage('User saved');
    } else {
      ScaffoldMessenger.of(context).showMessage('Failed to save user', error: true);
    }
  }

  Future<void> _syncToClient() async {
    final payload = _users
        .map((e) => {
              'username': e['username'],
              'password_hash': e['password_hash'] ?? '',
              'role': e['role'] ?? 'user',
            })
        .toList();
    final ok = await SupabaseService.sendRemoteCommand(
      clientId: widget.clientId,
      command: 'sync_users',
      parameters: {'users': payload},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMessage(ok ? 'Sync requested' : 'Failed to queue sync', error: !ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Users • ${widget.clientName}',
                style: GoogleFonts.poppins(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncToClient,
            tooltip: 'Sync to client',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userCtrl,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: GoogleFonts.poppins(color: Colors.white70),
                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.poppins(color: Colors.white70),
                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _role,
                        dropdownColor: Colors.black,
                        style: GoogleFonts.poppins(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                        ],
                        onChanged: (v) => setState(() => _role = v ?? 'user'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addUser,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add/Update'),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.white70),
                        title: Text(u['username'] ?? '', style: GoogleFonts.poppins(color: Colors.white)),
                        subtitle: Text('Role: ${u['role'] ?? 'user'}', style: GoogleFonts.poppins(color: Colors.white70)),
                        trailing: IconButton(
                          icon: const Icon(Icons.sync, color: Colors.white70),
                          tooltip: 'Queue sync of this user only',
                          onPressed: () async {
                            final payload = [
                              {
                                'username': u['username'],
                                'password_hash': u['password_hash'] ?? '',
                                'role': u['role'] ?? 'user',
                              }
                            ];
                            final ok = await SupabaseService.sendRemoteCommand(
                              clientId: widget.clientId,
                              command: 'sync_users',
                              parameters: {'users': payload},
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showMessage(ok ? 'Sync requested' : 'Failed', error: !ok);
                          },
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}

extension _Snack on ScaffoldMessengerState {
  void showMessage(String msg, {bool error = false}) {
    showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: error ? Colors.red : const Color(0xFF2D3748),
    ));
  }
}


