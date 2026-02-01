class VoiceScripts {
  static String getGreeting(String name) =>
      "Hello $name! Welcome to Folyo. I'm your AI assistant. I'll be guiding you through Neel Modi's portfolio. Let's get started.";

  static const String intro =
      "This is Neel Modi. A Software Engineer and Flutter Developer based in Hubli, Karnataka. He specializes in building scalable mobile applications and delivering intuitive user experiences.";

  static const String about =
      "Neel has over 2.5 years of experience in the industry. He is proficient in Flutter, Dart, Firebase, and Power Automate. He holds a B.Tech in Information Technology from Ganpat University with a strong academic record.";

  static const String experience =
      "Currently, Neel works as a Flutter Developer at MWB Technologies. Previously, he contributed to projects at Codiste, Kode Dynamic, and Sunflower Lab, where he built scalable apps and optimized performance for global clients.";

  static const String projects =
      "Neel's portfolio includes diverse projects like SecureForce, Eardrum AI, and Pulse AI. From real-time security tracking to AI-driven podcast platforms, his work demonstrates versatility and technical expertise.";

  static const String contact =
      "Ready to build something amazing? You can connect with Neel via email, phone, or LinkedIn. Thank you for exploring his portfolio with me!";

  static Map<String, String> getAllScripts({String userName = 'User'}) {
    return {
      'greeting': getGreeting(userName),
      'bio_0': intro,
      'bio_1': about,
      'bio_2': experience,
      'bio_3': projects,
      'bio_4': contact,
    };
  }
}
