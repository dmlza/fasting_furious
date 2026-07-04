import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class MetabolicProcess {
  final String icon;
  final String label;
  final String description;
  final double Function(double hoursElapsed) calculate;
  final List<String> stages;
  final Color color;
  final String science;
  final String mechanism;
  final String optimalRange;
  final String whenYouBreak;
  final List<String> tips;
  final List<String> studies;

  const MetabolicProcess({
    required this.icon,
    required this.label,
    required this.description,
    required this.calculate,
    required this.stages,
    required this.color,
    required this.science,
    required this.mechanism,
    required this.optimalRange,
    required this.whenYouBreak,
    required this.tips,
    required this.studies,
  });
}

final List<MetabolicProcess> metabolicProcesses = [
  MetabolicProcess(
    icon: '\u{1FA78}',
    label: 'Insulin',
    description: 'Drops as blood sugar depletes, unlocking fat burning.',
    calculate: (h) {
      if (h <= 0) return 1.0;
      if (h >= 12) return 0.05;
      return max(0.05, 1.0 - (h / 12));
    },
    stages: ['Peak', 'Declining', 'Low', 'Minimal'],
    color: AppColors.coral,
    science: 'Insulin is the master metabolic switch. When elevated, it locks fat cells and prevents lipolysis. Fasting is the most potent natural insulin-lowering intervention available. A 2021 study in Cell Metabolism showed intermittent fasting reduces fasting insulin by 20-40% over 12 weeks, independent of weight loss.',
    mechanism: 'After eating, pancreatic beta-cells release insulin to shuttle glucose into cells. During fasting, insulin secretion drops to basal levels (50-70% reduction). This signals adipose tissue to release free fatty acids via hormone-sensitive lipase (HSL). Low insulin also upregulates AMPK, a cellular energy sensor that promotes fat oxidation.',
    optimalRange: 'Fasting insulin: 2-5 \u00B5IU/mL is optimal for fat burning. Above 10 suggests insulin resistance. Below 2 may indicate overproduction during extended fasts.',
    whenYouBreak: 'Breaking a fast with refined carbs causes a massive insulin spike (higher than usual due to upregulated GLUT4 transporters). This can cause reactive hypoglycemia. Always break with protein + fat + fiber.',
    tips: [
      'Black coffee may enhance insulin sensitivity by 20-30% (study: Eur J Clin Nutr)',
      'Apple cider vinegar before meals reduces postprandial insulin by 20-30%',
      'Resistance training is the most effective way to improve insulin sensitivity',
      'Sleep deprivation increases insulin resistance by up to 30%',
    ],
    studies: [
      'Mattson et al. (2017) - Fasting vs calorie restriction: similar metabolic benefits',
      'Sutton et al. (2018) - Early time-restricted feeding improves insulin sensitivity',
      'Longo & Mattson (2014) - Fasting: molecular mechanisms and clinical applications',
    ],
  ),
  MetabolicProcess(
    icon: '\u26A1',
    label: 'Blood Glucose',
    description: 'Blood sugar normalizes as stored glycogen is consumed.',
    calculate: (h) {
      if (h <= 0) return 1.0;
      if (h >= 8) return 0.3;
      return max(0.3, 1.0 - (h / 8));
    },
    stages: ['Elevated', 'Normalizing', 'Stable', 'Basal'],
    color: AppColors.amber,
    science: 'Your body maintains blood glucose at 70-100 mg/dL through multiple redundant systems. The liver stores ~100g of glycogen (400 kcal) which sustains blood sugar for 12-24 hours. After that, gluconeogenesis (GNG) converts glycerol from fat breakdown and amino acids from muscle protein into glucose. GNG is demand-driven, not supply-driven.',
    mechanism: 'Glucagon (insulin\'s counterpart) rises as blood glucose falls. It signals hepatocytes to break down glycogen via glycogenolysis. As glycogen depletes (~18h), GNG becomes primary. The brain consumes ~120g glucose/day but adapts to use ketones for up to 75% of energy, dramatically reducing glucose demand.',
    optimalRange: 'Fasting glucose: 70-90 mg/dL optimal. 90-100 is normal but not optimal. Below 65 may cause neuroglycopenia symptoms.',
    whenYouBreak: 'After fasting, muscles actively absorb glucose (GLUT4 translocation) even without insulin. This is why post-fast meals cause less glucose spike than you\'d expect.',
    tips: [
      'Walking for 15 min after eating reduces glucose spike by 30-50%',
      'Eating protein before carbs reduces glucose spike by 40%',
      'Cinnamon (1-6g) may reduce fasting glucose by 5-10%',
      'Cold exposure increases glucose uptake by brown adipose tissue',
    ],
    studies: [
      'Cahill (2006) - Fuel metabolism in starvation: the 100g/day brain glucose requirement',
      'Gerich (2010) - Role of insulin resistance in pathophysiology of type 2 diabetes',
    ],
  ),
  MetabolicProcess(
    icon: '\u{1F504}',
    label: 'Autophagy',
    description: 'Cells begin recycling damaged components. Deep cellular cleanup.',
    calculate: (h) {
      if (h < 12) return 0.0;
      if (h >= 48) return 1.0;
      return min(1.0, (h - 12) / 36);
    },
    stages: ['Inactive', 'Initiating', 'Ramping', 'Peak'],
    color: AppColors.emerald,
    science: 'Autophagy (Greek: "self-eating") is the cell\'s quality control system. It degrades damaged organelles, misfolded proteins, and intracellular pathogens via lysosomes. Yoshinori Ohsumi won the 2016 Nobel Prize for elucidating autophagy mechanisms. Autophagy dysfunction is linked to neurodegeneration (Alzheimer\'s, Parkinson\'s), cancer, and aging.',
    mechanism: 'mTORC1 (mechanistic target of rapamycin complex 1) is the master regulator. When nutrients are abundant, mTORC1 inhibits autophagy. Fasting inactivates mTORC1 via AMPK activation and reduced amino acid signaling. This de-represses ULK1, initiating autophagosome formation. The autophagosome engulfs cargo and fuses with lysosomes for degradation.',
    optimalRange: 'Begins measurably at 12-16h. Peaks at 48-72h. Most benefits occur in the 16-36h range. Impossible to measure directly without tissue biopsy.',
    whenYouBreak: 'Protein intake (especially leucine) immediately activates mTORC1 and suppresses autophagy. To maximize autophagy benefits, extend the fast as long as possible before eating.',
    tips: [
      'Coffee enhances autophagy via AMPK activation (Nakajima et al., 2014)',
      'Spermidine (found in wheat germ, soybeans) is a potent autophagy inducer',
      'Exercise during fasting activates autophagy in muscle via AMPK',
      'Rapamycin (mTOR inhibitor) pharmacologically mimics fasting-induced autophagy',
    ],
    studies: [
      'Ohsumi (2016 Nobel) - Mechanisms of autophagy',
      'Bagherniya et al. (2018) - The effect of fasting or calorie restriction on autophagy induction',
      'Alirezaei et al. (2010) - Short-term fasting induces profound neuronal autophagy',
    ],
  ),
  MetabolicProcess(
    icon: '\u{1F525}',
    label: 'Ketone Production',
    description: 'Body shifts from glucose to fat as primary fuel source.',
    calculate: (h) {
      if (h < 8) return 0.0;
      if (h >= 48) return 1.0;
      return min(1.0, (h - 8) / 40);
    },
    stages: ['Glucose', 'Transitioning', 'Ketosis', 'Deep Ketosis'],
    color: AppColors.indigo,
    science: 'Ketogenesis converts fatty acids into ketone bodies (BHB, acetoacetate, acetone) in hepatic mitochondria. The brain cannot oxidize fatty acids (too large to cross blood-brain barrier) but readily uses ketones. BHB is not just fuel \u2014 it\'s also a signaling molecule that inhibits class I HDACs (epigenetic modification) and activates the HCAR2 receptor (anti-inflammatory).',
    mechanism: 'As insulin drops and glucagon rises, hormone-sensitive lipase (HSL) liberates free fatty acids from adipose tissue. Fatty acids undergo beta-oxidation in liver mitochondria to produce acetyl-CoA. When acetyl-CoA exceeds TCA capacity, it\'s shunted to ketogenesis via HMG-CoA synthase. BHB reaches brain via MCT1 transporters.',
    optimalRange: 'Mild: 0.3-0.5 mM. Nutritional ketosis: 0.5-3.0 mM. Therapeutic: 3.0-5.0 mM. Above 10 mM = ketoacidosis (medical emergency, only in T1D).',
    whenYouBreak: 'Eating protein triggers a small insulin response but doesn\'t rapidly exit ketosis. Carbs will spike insulin and halt ketone production within 1-2 hours.',
    tips: [
      'Exogenous BHB supplements raise blood ketones without fasting',
      'MCT oil is rapidly converted to ketones (C8 > C10)',
      'Keto-adaptation takes 2-4 weeks for full brain adaptation',
      'Ketones produce fewer ROS than glucose (more efficient fuel)',
    ],
    studies: [
      'Veech (2004) - The therapeutic implications of ketone bodies',
      'Newman & Verdin (2017) - Ketone bodies as signaling metabolites',
      'Puchalska & Crawford (2017) - Multi-dimensional roles of ketone bodies in metabolism',
    ],
  ),
  MetabolicProcess(
    icon: '\u{1F4AA}',
    label: 'Growth Hormone',
    description: 'Spikes to preserve muscle mass and burn fat for energy.',
    calculate: (h) {
      if (h < 8) return 0.1;
      if (h < 24) return min(1.0, 0.1 + (h - 8) / 16 * 0.9);
      return max(0.5, 1.0 - (h - 24) / 48);
    },
    stages: ['Baseline', 'Rising', 'Elevated', 'Peak'],
    color: AppColors.emerald,
    science: 'Growth hormone (GH) increases 2-5x during 24h fasts and up to 5x during 5-day fasts (Ho et al., 1988). Unlike calorie restriction which suppresses GH, fasting preserves it. GH promotes lipolysis, spares muscle protein, and stimulates IGF-1 for tissue repair. This is why fasting preserves lean mass better than equivalent calorie reduction.',
    mechanism: 'GH is secreted by anterior pituitary somatotroph cells in a pulsatile pattern, regulated by GHRH (stimulatory) and somatostatin (inhibitory). Fasting suppresses somatostatin and enhances GHRH. Low blood glucose and low IGF-1 levels further disinhibit GH release. GH acts on liver to produce IGF-1, which mediates many growth effects.',
    optimalRange: 'Fasting GH peaks at 12-24h. Normal range: 0.4-10 ng/mL. During fasting: 10-30 ng/mL is common.',
    whenYouBreak: 'GH levels normalize quickly after eating. Protein meals stimulate GH less than fat meals. Sugar suppresses GH.',
    tips: [
      'Deep sleep (stage 3 NREM) produces 70% of daily GH release',
      'High-intensity interval training (HIIT) boosts GH by 300-450%',
      'Arginine supplementation (5-9g) may increase GH secretion',
      'Avoid sugar before bed \u2014 it suppresses nocturnal GH pulses',
    ],
    studies: [
      'Ho et al. (1988) - Prolonged fasting suppresses somatomedin-C',
      'Fazeli & Klibanski (2014) - Effects of prolonged fasting on bone metabolism',
      'Rudman et al. (1990) - GH and body composition changes with aging',
    ],
  ),
  MetabolicProcess(
    icon: '\u{1F9E0}',
    label: 'Norepinephrine',
    description: 'Increases focus and alertness. Fat cells release norepinephrine.',
    calculate: (h) {
      if (h < 12) return 0.1;
      if (h >= 48) return 1.0;
      return min(1.0, 0.1 + (h - 12) / 36);
    },
    stages: ['Baseline', 'Rising', 'Enhanced', 'Peak Focus'],
    color: AppColors.amber,
    science: 'Norepinephrine (NE) is released by sympathetic nerve terminals and adrenal medulla during fasting. NE activates beta-adrenergic receptors on fat cells, triggering lipolysis. It also crosses the blood-brain barrier, enhancing alertness, attention, and memory consolidation. This is an evolutionary adaptation for hunting efficiency during food scarcity.',
    mechanism: 'Fasting activates the sympathetic nervous system via hypothalamic orexin neurons. NE binds beta-3 adrenergic receptors on adipocytes, activating adenylyl cyclase -> cAMP -> PKA -> HSL phosphorylation -> fat breakdown. NE also enhances prefrontal cortex activity via alpha-2A adrenoceptors.',
    optimalRange: 'Moderate NE elevation improves focus. Excessive levels (>2x baseline) may cause anxiety, tremor, or insomnia.',
    whenYouBreak: 'NE levels normalize after eating. Caffeine + fasting = synergistic NE release. Be cautious with stimulant stacking.',
    tips: [
      'Morning fasting maximizes circadian NE peak (6-10 AM)',
      'Cold exposure (50-59\u00B0F) increases NE by 200-300%',
      'Meditation increases NE receptor density (chronic adaptation)',
      'NE has a half-life of 2-3 minutes \u2014 effects are acute, not lasting',
    ],
    studies: [
      'Zarich et al. (1997) - Fasting augments the thermogenic response to catecholamines',
      'Webber et al. (2016) - Norepinephrine in fasting: from evolution to intervention',
    ],
  ),
];

class Milestone {
  final double hour;
  final String icon;
  final String title;
  final String message;
  final String encouragement;

  const Milestone({
    required this.hour,
    required this.icon,
    required this.title,
    required this.message,
    required this.encouragement,
  });
}

const List<Milestone> fastingMilestones = [
  Milestone(
    hour: 4,
    icon: '\u{1F31F}',
    title: 'Metabolic Switch Activated',
    message: 'Your body has entered the fasting state. Insulin is dropping, fat burning is beginning.',
    encouragement: 'Great start! You\'re already making progress.',
  ),
  Milestone(
    hour: 8,
    icon: '\u26A1',
    title: 'Fat Burning Begins',
    message: 'Glycogen is depleting. Your body is starting to tap into fat stores for energy.',
    encouragement: 'You\'re past the hardest part \u2014 the hunger phase. Keep going!',
  ),
  Milestone(
    hour: 12,
    icon: '\u{1F504}',
    title: 'Autophagy Switching On',
    message: 'Your cells are beginning to recycle damaged components. Cellular cleanup has started.',
    encouragement: 'This is where the magic happens. Every minute counts now.',
  ),
  Milestone(
    hour: 16,
    icon: '\u{1F525}',
    title: 'Full Fat-Burning Mode',
    message: 'Ketone production is rising. Autophagy is ramping up. You\'re in deep fasting territory.',
    encouragement: 'Incredible discipline. Your body is thanking you.',
  ),
  Milestone(
    hour: 24,
    icon: '\u{1F4AA}',
    title: 'Growth Hormone Peak',
    message: 'Growth hormone has spiked up to 5x. Your body is protecting muscle and burning pure fat.',
    encouragement: '24 hours \u2014 that\'s elite territory. Most people never get here.',
  ),
  Milestone(
    hour: 36,
    icon: '\u{1F9E0}',
    title: 'Deep Ketosis',
    message: 'Your brain is running on ketones. Maximum mental clarity. Peak autophagy approaching.',
    encouragement: 'You\'re operating at a level 99% of people never experience.',
  ),
  Milestone(
    hour: 48,
    icon: '\u{1F3AF}',
    title: 'Autophagy Peak',
    message: 'Maximum cellular recycling. Immune system regeneration is underway.',
    encouragement: 'This is genuinely remarkable. You\'ve achieved something extraordinary.',
  ),
  Milestone(
    hour: 72,
    icon: '\u2B50',
    title: 'Extended Fast Mastered',
    message: '72 hours complete. Maximum autophagy. Stem cell regeneration activated.',
    encouragement: 'Legendary. Consult a healthcare professional before extending further.',
  ),
];

class MetabolicDashboard extends StatefulWidget {
  final double hoursElapsed;

  const MetabolicDashboard({super.key, required this.hoursElapsed});

  @override
  State<MetabolicDashboard> createState() => _MetabolicDashboardState();
}

class _MetabolicDashboardState extends State<MetabolicDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getPhaseName() {
    final h = widget.hoursElapsed;
    if (h < 4) return 'Fed State';
    if (h < 12) return 'Early Fasting';
    if (h < 18) return 'Glycogen Depletion';
    if (h < 36) return 'Fat Burning';
    if (h < 72) return 'Deep Fasting';
    return 'Extended Fast';
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Milestone? _getLatestMilestone() {
    Milestone? latest;
    for (final m in fastingMilestones) {
      if (widget.hoursElapsed >= m.hour) {
        latest = m;
      }
    }
    return latest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildEncouragementBanner(theme),
            const SizedBox(height: 20),
            _buildAchievedCount(theme),
            const SizedBox(height: 12),
            ...metabolicProcesses.asMap().entries.map((entry) {
              final i = entry.key;
              final process = entry.value;
              final target = process.calculate(widget.hoursElapsed);
              final current = target * _animation.value;
              final stageIndex = (current * (process.stages.length - 1)).floor().clamp(0, process.stages.length - 1);
              final isExpanded = _expandedIndex == i;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MetabolicRing(
                  process: process,
                  value: current,
                  stageLabel: process.stages[stageIndex],
                  isExpanded: isExpanded,
                  hoursElapsed: widget.hoursElapsed,
                  onTap: () => setState(() {
                    _expandedIndex = isExpanded ? null : i;
                  }),
                ),
              );
            }),
            const SizedBox(height: 8),
            _buildCurrentPhaseInfo(theme),
            const SizedBox(height: 12),
            _buildMilestoneTimeline(theme),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        const Text('\u{1F9EA}', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Metabolic Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                '${_formatHours(widget.hoursElapsed)} fasting \u2022 ${_getPhaseName()}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEncouragementBanner(ThemeData theme) {
    final milestone = _getLatestMilestone();
    if (milestone == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.indigo.withValues(alpha: 0.08),
              AppColors.emerald.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.indigo.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Text('\u{1F31F}', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fast In Progress',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Your body is already adapting. Every minute you stay in the fasted state brings metabolic benefits.',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.indigo.withValues(alpha: 0.08),
            AppColors.emerald.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(milestone.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  milestone.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            milestone.message,
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, height: 1.3),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              milestone.encouragement,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievedCount(ThemeData theme) {
    final achieved = metabolicProcesses.where((p) => p.calculate(widget.hoursElapsed) > 0.5).length;
    return Row(
      children: [
        Icon(Icons.bolt, size: 16, color: AppColors.amber),
        const SizedBox(width: 6),
        Text(
          '$achieved of ${metabolicProcesses.length} processes active',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color),
        ),
        const Spacer(),
        if (achieved >= 4)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '\u{1F525} On Fire',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentPhaseInfo(ThemeData theme) {
    final h = widget.hoursElapsed;
    String title;
    String detail;
    String impact;

    if (h < 4) {
      title = 'Your Body Is Using Recent Meals';
      detail = 'Insulin is elevated from your last meal. Blood sugar is being processed and stored as glycogen in the liver and muscles.';
      impact = 'Caloric energy from food is your primary fuel. Fat storage is active.';
    } else if (h < 12) {
      title = 'Transitioning to Fat Burning';
      detail = 'Insulin levels are dropping. Your body is beginning to tap into glycogen stores. Growth hormone starts to rise to preserve muscle.';
      impact = 'You\'re burning through stored carbs. Fat mobilization is beginning.';
    } else if (h < 18) {
      title = 'Glycogen Stores Depleting';
      detail = 'Liver glycogen is running low. Autophagy is initiating \u2014 cells begin recycling damaged proteins and organelles.';
      impact = 'Autophagy markers are rising. Cellular cleanup has begun.';
    } else if (h < 36) {
      title = 'Deep Fat Burning Mode';
      detail = 'Ketone production is ramping up. Your brain is adapting to use ketones for fuel. Autophagy is accelerating.';
      impact = 'You\'re now burning predominantly fat. Mental clarity is enhanced.';
    } else if (h < 72) {
      title = 'Peak Metabolic Benefits';
      detail = 'Autophagy is at its peak. Growth hormone is elevated. Immune system is being regenerated. Deep cellular repair is underway.';
      impact = 'Maximum cellular renewal. Stem cell activity is increasing.';
    } else {
      title = 'Extended Fasting State';
      detail = 'Maximum autophagy and cellular renewal. Consult a healthcare professional for extended fasts beyond 72 hours.';
      impact = 'Extraordinary metabolic state. Professional guidance recommended.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(detail, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.indigo.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  impact,
                  style: TextStyle(fontSize: 11, color: AppColors.indigo.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTimeline(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Milestone Roadmap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...fastingMilestones.map((m) {
          final achieved = widget.hoursElapsed >= m.hour;
          final isNext = !achieved && fastingMilestones.indexOf(m) > 0 &&
              widget.hoursElapsed >= fastingMilestones[fastingMilestones.indexOf(m) - 1].hour;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: achieved
                  ? AppColors.emerald.withValues(alpha: 0.06)
                  : isNext
                      ? AppColors.amber.withValues(alpha: 0.04)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isNext
                  ? Border.all(color: AppColors.amber.withValues(alpha: 0.3))
                  : achieved
                      ? Border.all(color: AppColors.emerald.withValues(alpha: 0.15))
                      : null,
            ),
            child: Row(
              children: [
                Text(
                  achieved ? '\u2705' : isNext ? '\u{1F534}' : '\u{1F512}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatHours(m.hour.toDouble())} \u2014 ${m.title}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: achieved ? AppColors.emerald : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNext)
                  Text(
                    '${(m.hour - widget.hoursElapsed).toStringAsFixed(0)}h left',
                    style: TextStyle(fontSize: 10, color: AppColors.amber, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MetabolicRing extends StatelessWidget {
  final MetabolicProcess process;
  final double value;
  final String stageLabel;
  final bool isExpanded;
  final VoidCallback onTap;
  final double hoursElapsed;

  const _MetabolicRing({
    required this.process,
    required this.value,
    required this.stageLabel,
    required this.isExpanded,
    required this.onTap,
    required this.hoursElapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (value * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isExpanded
              ? process.color.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isExpanded
              ? Border.all(color: process.color.withValues(alpha: 0.2))
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _RingPainter(
                      value: value,
                      color: process.color,
                      trackColor: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: process.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(process.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            process.label,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: process.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stageLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: process.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        process.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? _buildDetailCard(theme)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: process.color.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          _buildDetailSection(
            icon: '\u{1F52C}',
            title: 'The Science',
            text: process.science,
            color: process.color,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _buildDetailSection(
            icon: '\u2699\uFE0F',
            title: 'How It Works',
            text: process.mechanism,
            color: process.color,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _buildDetailSection(
            icon: '\u{1F4CF}',
            title: 'Optimal Range',
            text: process.optimalRange,
            color: process.color,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _buildDetailSection(
            icon: '\u{1F37D}\u{FE0F}',
            title: 'When You Break The Fast',
            text: process.whenYouBreak,
            color: process.color,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _buildTipsSection(theme),
          const SizedBox(height: 10),
          _buildStudiesSection(theme),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String icon,
    required String title,
    required String text,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(text, style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\u{1F4A1}', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pro Tips', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: process.color)),
              const SizedBox(height: 4),
              ...process.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\u2022 ', style: TextStyle(fontSize: 11, color: process.color, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(tip, style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color, height: 1.3)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudiesSection(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\u{1F4DA}', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key Research', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: process.color)),
              const SizedBox(height: 4),
              ...process.studies.map((study) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\u2022 ', style: TextStyle(fontSize: 11, color: process.color, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(study, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color, height: 1.3, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 5.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
