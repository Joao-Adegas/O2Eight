import '../models/community_post.dart';
import '../models/metrics.dart';

class MockDataService {
  static final puffHistory = <DayMetric>[
    const DayMetric('Seg', 38),
    const DayMetric('Ter', 45),
    const DayMetric('Qua', 22),
    const DayMetric('Qui', 30),
    const DayMetric('Sex', 18),
    const DayMetric('Sab', 12),
    const DayMetric('Dom', 8),
  ];

  static final savingsData = <DayMetric>[
    const DayMetric('S1', 28),
    const DayMetric('S2', 56),
    const DayMetric('S3', 84),
    const DayMetric('S4', 112),
    const DayMetric('S5', 147),
    const DayMetric('S6', 189),
  ];

  static final triggers = <TriggerMetric>[
    const TriggerMetric('Cafe', 34, 82),
    const TriggerMetric('Estresse', 28, 68),
    const TriggerMetric('Tedio', 19, 46),
    const TriggerMetric('Social', 14, 34),
  ];

  static final criticalHours = <HourRisk>[
    const HourRisk('07h', 20),
    const HourRisk('10h', 75),
    const HourRisk('13h', 55),
    const HourRisk('16h', 90),
    const HourRisk('19h', 40),
    const HourRisk('22h', 30),
  ];

  static final milestones = <Milestone>[
    const Milestone('20 min', 'Pressao arterial normalizada', true),
    const Milestone('8 h', 'Oxigenio no sangue normalizado', true),
    const Milestone('24 h', 'Risco de infarto reduzido', true),
    const Milestone('48 h', 'Paladar e olfato em recuperacao', false),
    const Milestone('72 h', 'Bronquios se dilatam', false),
    const Milestone('2 sem', 'Circulacao visivelmente melhorada', false),
  ];

  static const aiResponses = <String, String>{
    'default': 'Entendo o que voce esta sentindo, Lucas. Voce ja economizou R\$ 189. Respira fundo por 4 segundos, segura 4 e solta 4. Voce ja venceu antes e vence de novo.',
    'cafe': 'Gatilho do cafe detectado. Troque o ritual por cafe e agua gelada. O frio na garganta ajuda a reduzir o reflexo da tragada.',
    'estresse': 'Estresse intenso detectado. Nomeie 3 objetos que voce ve agora para interromper o loop da fissura.',
    'tedio': 'Tedio e um gatilho forte. Tente 5 minutos de musica e movimento para redirecionar o foco.',
  };

  static final posts = <CommunityPost>[
    const CommunityPost(
      id: 1,
      author: 'Maria Silva',
      avatar: 'M',
      daysClean: 120,
      text: '120 dias! Nos primeiros 15 dias pensei em desistir varias vezes. Hoje valeu cada dia.',
      likes: 47,
      comments: 12,
      timeAgo: '2h atras',
      badge: '4 meses',
    ),
    const CommunityPost(
      id: 2,
      author: 'Pedro Costa',
      avatar: 'P',
      daysClean: 7,
      text: 'Primeira semana completa. O chat da IA me salvou ontem na madrugada.',
      likes: 89,
      comments: 24,
      timeAgo: '5h atras',
      badge: '1 semana',
    ),
    const CommunityPost(
      id: 3,
      author: 'Ana Santos',
      avatar: 'A',
      daysClean: 365,
      text: 'Um ano sem fumar! Nao desistam. Cada dia conta.',
      likes: 234,
      comments: 56,
      timeAgo: '1 dia atras',
      badge: '1 ano',
    ),
  ];

  static final clusterData = <ClusterData>[
    const ClusterData('Perfil A Estresse', 34, 78),
    const ClusterData('Perfil B Cafe', 28, 64),
    const ClusterData('Perfil C Social', 19, 85),
    const ClusterData('Perfil D Tedio', 14, 71),
  ];
}
