import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' as developer;
import 'api_key_service.dart';

class GeminiService {
  
  // Inserisci la tua chiave API di Google AI Studio
  final modelName = 'gemini-3.5-flash-lite';
  Future<Map<String, String>> extractPumpDataByImageWithAI(File imageFile) async {
    // Prendo la chiave
    final apiKey = await ApiKeyService.getActiveApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      // Gestisci il caso in cui la chiave non esiste (es. reindirizza alla schermata di configurazione)
      return {'importo': '', 'litri': ''};
    }
    // Usiamo un modello veloce ed economico come gemini-1.5-flash
    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    // Leggi l'immagine in byte
    final imageBytes = await imageFile.readAsBytes();

    // Prompt chiaro e diretto per l'IA
    final prompt = '''
    Questa è la foto del display di un distributore di carburante. 
    Estrai esattamente due valori numerici:
    1. L'importo in euro (solitamente il numero più in alto, es. 15.20)
    2. I litri erogati (solitamente il numero più in basso, es. 7.64)
    
    Rispondi ESATTAMENTE in questo formato JSON, senza altro testo:
    {"importo": "15.20", "litri": "7.64"}
    ''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    return getAiResponseText(model, content).then((responseText) {
      if (responseText != null) {
        developer.log('AI answer: $responseText',name:"FuelLog.gemini_service");
        try {
          final Map<String, dynamic> jsonResponse = json.decode(responseText);
          return {
            'importo': jsonResponse['importo'] ?? '',
            'litri': jsonResponse['litri'] ?? '',
          };
        } catch (e) {
          developer.log('Error parsing JSON: $e', name:"FuelLog.gemini_service");
          return {'importo': '', 'litri': '','error':"$e"};
        }
      } else {
        developer.log('No answwer from AI.',name:"FuelLog.gemini_service");
        return {'importo': '', 'litri': '','error':'no_answer_from_ai'};
      }
    });
  }

  Future<Map<String, String>> extractOdometerDataByImageWithAI(File imageFile) async {
    // Prendo la chiave
    final apiKey = await ApiKeyService.getActiveApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      // Gestisci il caso in cui la chiave non esiste (es. reindirizza alla schermata di configurazione)
      return {'importo': '', 'litri': ''};
    }
    // Usiamo un modello veloce ed economico come gemini-1.5-flash
    final model = GenerativeModel(model: modelName, apiKey: apiKey);

    // Leggi l'immagine in byte
    final imageBytes = await imageFile.readAsBytes();

    // Prompt chiaro e diretto per l'IA
    final prompt = '''
    Questa è la foto di un cruscotto. 
    Estrai esattamente un valore numerico:
    1. I chilometri percorsi (solitamente il numero al centro del tachimetro, es. 12345.6)

    Rispondi ESATTAMENTE in questo formato JSON, senza altro testo:
    {"km": "12345.6"}
    ''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    return getAiResponseText(model, content).then((responseText) {
      if (responseText != null) {
        try {
          final Map<String, dynamic> jsonResponse = json.decode(responseText);
          return {
            'km': jsonResponse['km'] ?? '',
          };
        } catch (e) {
          developer.log('Error parsing JSON: $e', name:"FuelLog.gemini_service");
          return {'km': '','error':"$e"};
        }
      } else {
        developer.log('No answwer from AI.',name:"FuelLog.gemini_service");
        return {'km': '', 'error': 'no_answer_from_ai'};
      }
    });
  }

  Future<String?> getAiResponseText(GenerativeModel model, List<Content> content) async {
    try {
      // Supponendo che response.text contenga la stringa JSON
      // Invia la richiesta all'IA
      final response = await model.generateContent(content);
      developer.log('AI answer: ${response.text}');
      String? rawText = response.text;

      if (rawText != null) {
        // Pulisci eventuali blocchi di codice markdown se l'IA li ha aggiunti (es. ```json ... ```)
        String cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        
        return cleanJson;
      }
      // Restituisce il testo generato (può essere null se la risposta è stata bloccata per sicurezza)
      return null;
    } catch (e) {
      developer.log('Error AI: $e',name:"FuelLog.gemini_service");
      return null;
    }
  }
}