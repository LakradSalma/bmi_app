import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
        backgroundColor: Colors.green,
      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bmi_data')
                  .where('email', isEqualTo: user.email)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Vérification des erreurs
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                // Vérification de l'état de la connexion
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Récupérer les documents
                final docs = snapshot.data!.docs;

                // Vérification si aucun document n'est trouvé
                if (docs.isEmpty) {
                  return const Center(child: Text("No history found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data()! as Map<String, dynamic>;

                    // Vérifier que les données nécessaires sont présentes
                    final bmi = data['bmi'];
                    final timestamp = data['timestamp'];
                    if (bmi == null || timestamp == null) {
                      return const Center(child: Text("Invalid data"));
                    }

                    final date = (timestamp as Timestamp).toDate();

                    return ListTile(
                      title: Text("BMI: ${bmi.toStringAsFixed(2)}"),
                      subtitle: Text("Date: $date"),
                    );
                  },
                );
              },
            ),
    );
  }
}
