

import 'package:ira_spa_webapp/models/spa_service.dart';

final Map<String, List<SpaService>> spaMenuData = {
  'Massages': [
    SpaService(
      id: 'massage_swedish',
      title: 'Swedish Massage',
      description:
          'A classic full-body massage to relax muscles and improve circulation.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 1800),
        ServiceOption(label: '90 min', duration: 90, price: 2500),
      ],
    ),
    SpaService(
      id: 'massage_deep_tissue',
      title: 'Deep Tissue Massage',
      description:
          'Targeted pressure to relieve chronic muscle tension and knots.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2200),
        ServiceOption(label: '90 min', duration: 90, price: 3000),
      ],
    ),
  ],
  'Facials': [
    SpaService(
      id: 'facial_hydration',
      title: 'Hydrating Facial',
      description:
          'Deep hydration to restore glow and balance skin moisture.',
      options: const [
        ServiceOption(label: '45 min', duration: 45, price: 1400),
        ServiceOption(label: '60 min', duration: 60, price: 1800),
      ],
    ),
    SpaService(
      id: 'facial_anti_aging',
      title: 'Anti-Aging Facial',
      description:
          'Firming facial to smooth fine lines and refresh your complexion.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2200),
      ],
    ),
  ],
  'Body Treatments': [
    SpaService(
      id: 'body_scrub',
      title: 'Body Scrub',
      description:
          'Exfoliating scrub to renew skin texture and softness.',
      options: const [
        ServiceOption(label: '45 min', duration: 45, price: 1500),
      ],
    ),
    SpaService(
      id: 'body_wrap',
      title: 'Detox Body Wrap',
      description:
          'A detoxifying wrap to rejuvenate and tone the body.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2100),
      ],
    ),
  ],
};

