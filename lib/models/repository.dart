import 'package:ira_spa_webapp/models/spa_service.dart';

final Map<String, List<SpaService>> spaMenuData = {
  'Body Massage': [
    SpaService(
      id: 'massage_classic_swedish',
      title: 'CLASSIC SWEDISH THERAPY',
      description:
          'Classic Swedish techniques create the ultimate experience of relaxation during this full body therapy which reduces tension, increases circulation and flexibility',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2200),
        ServiceOption(label: '90 min', duration: 90, price: 3300),
        ServiceOption(label: '120 min', duration: 120, price: 4000),
      ],
    ),
    SpaService(
      id: 'massage_deep_tissue',
      title: 'DEEP TISSUE THERAPY',
      description:
          'Deep Tissue technique uses slow, deep guided strokes and firm pressure designed to relieve severe tension and reach below the superficial muscles, consistent pain and soreness in muscles',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2750),
        ServiceOption(label: '90 min', duration: 90, price: 4000),
        ServiceOption(label: '120 min', duration: 120, price: 5500),
      ],
    ),
    SpaService(
      id: 'massage_aroma',
      title: 'AROMA THERAPY',
      description:
          'Aromatherapy is a powerful way to enhance the effectiveness of massage. It can calm the nerves, promote physical and emotional health, lift the spirits, and energize the body.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2400),
        ServiceOption(label: '90 min', duration: 90, price: 3600),
        ServiceOption(label: '120 min', duration: 120, price: 4800),
      ],
    ),
    SpaService(
      id: 'massage_balinese',
      title: 'BALINESE THERAPY',
      description:
          'The combination of technique, acupressure, Aroma Essential Oil and reflexology allows to work especially well on achy joints and muscle strains. It helps to ease sleep disorders, and many people find that the techniques are good for reducing stress and anxiety, and boosting a person\'s general sense of well-being.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2750),
        ServiceOption(label: '90 min', duration: 90, price: 4000),
        ServiceOption(label: '120 min', duration: 120, price: 5500),
      ],
    ),
    SpaService(
      id: 'massage_ira_signature',
      title: 'IRA SIGNATURE THERAPY',
      description:
          'Ira Signature simultaneously connects and revitalizes body, mind, heart and soul. Working at the core of our being, it calms, inspires and empowers us to create the life we desire. It nurtures us with healing and abundant blessings, improves all systems and organs, cleansing and detoxifying, brings harmony and balance.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3000),
        ServiceOption(label: '90 min', duration: 90, price: 4500),
      ],
    ),
    SpaService(
      id: 'massage_tandem',
      title: 'TANDEM (FOURS HANDS) THERAPY',
      description:
          'Tandem Therapy is a specialized therapy conducted by two therapists at a time. Use of targeted techniques to break down the build up of tissue around the muscles that cause pain, aches and inflammation, massage around long, slow sweeping movements will put the whole body into a state of relaxation',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 4000),
        ServiceOption(label: '90 min', duration: 90, price: 5500),
      ],
    ),
  ],
  'Herbal Therapy': [
    SpaService(
      id: 'herbal_potli',
      title: 'HERBAL POTLI',
      description:
          'Potli therapy is performed using heated herbal pouches. These are used to massage and provide heat to the whole body or specific areas like the lower back, neck and joints that helps to Reduces inflammation, Improves mobility & flexibility, Relieves pain, Stiffness in joints and Muscular spasms.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3000),
        ServiceOption(label: '90 min', duration: 90, price: 4000),
      ],
    ),
    SpaService(
      id: 'herbal_hot_stone',
      title: 'HOT STONE THERAPY',
      description:
          'Hot stone therapy involves placing hot stones on several spots of the body. The power from the hot stones and warm herbal oil will balance the circulation of blood and improve your excretory system. This massage is suitable for those who are tired from hard work, insufficient sleep, and suffered from abnormal excretory system.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3200),
        ServiceOption(label: '90 min', duration: 90, price: 4800),
      ],
    ),
  ],
  'Thai Therapy': [
    SpaService(
      id: 'thai_traditional',
      title: 'TRADITIONAL THAI THERAPY',
      description:
          'Thai aroma massage blends East and West techniques. Thai-style deep massage with stretching is combined with sophisticated western-style. This Therapy slowly takes away the strain of the daily grind, revitalizes your energy and leaves you feeling totally relaxed and peaceful.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2400),
        ServiceOption(label: '90 min', duration: 90, price: 3600),
        ServiceOption(label: '120 min', duration: 120, price: 4800),
      ],
    ),
    SpaService(
      id: 'thai_bamboo',
      title: 'BAMBOO THERAPY',
      description:
          'Bamboo massage is yet another unusual type of holistic treatment. It is believed that bamboo massage has many healing properties which help to alleviate muscle tension; pain and ache; improve joint function; increase circulation and helps to enhance quality of sleep.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 4000),
        ServiceOption(label: '90 min', duration: 90, price: 5500),
      ],
    ),
  ],
  'Body Polishing': [
    SpaService(
      id: 'polishing_black_currant',
      title: 'FULL BODY - Black Currant (Dry Skin)',
      description:
          'A popular body treatment that exfoliates and hydrates your skin, leaving it smooth, soft and glowing with a uniform tone across the body.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3500),
      ],
    ),
    SpaService(
      id: 'polishing_chocolate',
      title: 'FULL BODY - Chocolate (Brightening and Nourishing)',
      description:
          'A popular body treatment that exfoliates and hydrates your skin, leaving it smooth, soft and glowing with a uniform tone across the body.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3500),
      ],
    ),
    SpaService(
      id: 'polishing_orange',
      title: 'FULL BODY - Orange (De-tan)',
      description:
          'A popular body treatment that exfoliates and hydrates your skin, leaving it smooth, soft and glowing with a uniform tone across the body.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3500),
      ],
    ),
  ],
  'Clean-Ups And Facial-Essential': [
    SpaService(
      id: 'cleanup_watermelon',
      title: 'WATERMELON CLEAN-UP',
      description: 'Clean-up for refreshed and nourished skin.',
      options: const [
        ServiceOption(label: '30 min', duration: 30, price: 700),
      ],
    ),
    SpaService(
      id: 'cleanup_strawberry',
      title: 'STRAWBERRY CLEAN-UP',
      description: 'Clean-up for refreshed and nourished skin.',
      options: const [
        ServiceOption(label: '30 min', duration: 30, price: 800),
      ],
    ),
    SpaService(
      id: 'facial_hydra_dew',
      title: 'HYDRA DEW (Dry & Dehydrated)',
      description: 'Moisturize and soothe your delicate and dry skin with comfort and protection.',
      options: const [
        ServiceOption(label: '45 min', duration: 45, price: 1000),
      ],
    ),
    SpaService(
      id: 'facial_rejuvenating',
      title: 'REJUVENATING (All skin type)',
      description: 'Revitalize to leave a supple skin by proper exfoliation and enhanced blood circulation.',
      options: const [
        ServiceOption(label: '45 min', duration: 45, price: 1200),
      ],
    ),
    SpaService(
      id: 'facial_herbal_pearl',
      title: 'HERBAL PEARL',
      description: 'A natural retreat for your skin from handpicked herbal ingredients.',
      options: const [
        ServiceOption(label: '45 min', duration: 45, price: 2000),
      ],
    ),
  ],
  'Facial-Premium And Signature': [
    SpaService(
      id: 'facial_deep_pore',
      title: 'DEEP PORE CLEANSING (Oily Skin)',
      description:
          'Specially formulated with Larrea divaricata extract and Enantia chlorantha extract, softens oily skin resulting in a fresher complexion. Helps to control oil production, eliminate breakouts and, formulated with vitamins, anti-oxidants and natural herbs, to get a youthful skin.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2400),
      ],
    ),
    SpaService(
      id: 'facial_whitening',
      title: 'WHITENING FACIAL (Dull & Uneven Skin Tone)',
      description:
          'One of the most effective, fastest and safest approach to skin lightening by reducing Melanin formation. Contains broad-spectrum sun filters which minimize photo damage, promote even skin tone and reduce skin tanning on exposure to UV rays.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 2500),
      ],
    ),
    SpaService(
      id: 'facial_herbal_gold',
      title: 'HERBAL GOLD',
      description:
          'A natural retreat for your skin from handpicked herbal ingredients which gives instant results.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 3500),
      ],
    ),
  ],
  'Quick Massage': [
    SpaService(
      id: 'quick_foot_reflexology',
      title: 'FOOT REFLEXOLOGY',
      description: 'Stimulate and massage pressure points in legs to release the tension and relax tired legs.',
      options: const [
        ServiceOption(label: '30 min', duration: 30, price: 1200),
      ],
    ),
    SpaService(
      id: 'quick_back',
      title: 'BACK (without shower)',
      description: 'A soothing massage using different kind of essential oils for relaxing and de-stressing.',
      options: const [
        ServiceOption(label: '30 min', duration: 30, price: 1600),
      ],
    ),
    SpaService(
      id: 'quick_head_neck_shoulder',
      title: 'HEAD, NECK & SHOULDER',
      description: 'Relax, de-stress, revive, and renew the body with perfect massage strokes.',
      options: const [
        ServiceOption(label: '30 min', duration: 30, price: 1300),
      ],
    ),
  ],
  'Foot Spa': [
    SpaService(
      id: 'foot_classic_paraffin',
      title: 'CLASSIC PARAFFIN WAX PEDICURE (Melon & Litchi)',
      description: 'A soothing massage using different kind of essential oils for relaxing and de-stressing.',
      options: const [
        ServiceOption(label: '45 min', duration: 45, price: 800),
      ],
    ),
    SpaService(
      id: 'foot_anti_oxidant',
      title: 'ANTI-OXIDANT PEDICURE (Lemon)',
      description: 'A soothing massage using different kind of essential oils for relaxing and de-stressing.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 800),
      ],
    ),
    SpaService(
      id: 'foot_moisturizing_exotic',
      title: 'MOISTURIZING EXOTIC PEDICURE (Berry)',
      description: 'A soothing massage using different kind of essential oils for relaxing and de-stressing.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 800),
      ],
    ),
    SpaService(
      id: 'foot_brightening_detan',
      title: 'BRIGHTENING DE-TAN PEDICURE (Sheen Tangy)',
      description: 'A soothing massage using different kind of essential oils for relaxing and de-stressing.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 1200),
      ],
    ),
    SpaService(
      id: 'foot_destress_refreshment',
      title: 'DE-STRESS REFRESHMENT (Mint)',
      description: 'A soothing massage using different kind of essential oils for relaxing and de-stressing.',
      options: const [
        ServiceOption(label: '60 min', duration: 60, price: 1000),
      ],
    ),
  ],
};