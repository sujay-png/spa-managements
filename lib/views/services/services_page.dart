import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/views/services/services_data.dart';

class ServicePage extends StatelessWidget {
  const ServicePage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: SingleChildScrollView(
        padding:  const EdgeInsets.all(24), 
        child:Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
               //Header
               Text("Services",
                style: TextStyle(color: const Color(0xFF544436,),
                fontSize: 23,
                 fontWeight: FontWeight.w500,
                ),
                ),
                
               const SizedBox(height:5),
               
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
               
                        Text("Manage your spa services and treatment",
                        style:TextStyle(color: const Color.fromARGB(255, 121, 109, 100),
                        ),
                        ),
                      
                  
                    Spacer(),
                  
                    SizedBox(
                        width: 165,
                         height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C7A6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Service"),
                        ),
                      ),
                   
                  ],
                ),
               
            const SizedBox(width: 25, height: 30),
               //check it if grid views not works in another then add here
        ],
        ),
            
             GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 15,
                childAspectRatio: 1.21,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE8DDD2),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                );
              },
            ),
      
        
              
        ],
        ),
        
        
        ),
      );
  }
}
      
      
      
      
      
      
      
      
    