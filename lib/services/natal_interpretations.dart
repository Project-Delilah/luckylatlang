import '../models/natal_chart.dart';
import '../models/planet_line.dart';

// ── Ascendant sign descriptions ────────────────────────────────────────────────

const Map<ZodiacSign, String> ascendantDescriptions = {
  ZodiacSign.aries:
      'You come across as bold, energetic and direct — a natural leader who acts before asking permission. Others sense your drive and competitive spirit immediately. Your first impression is one of confidence and restless momentum.',
  ZodiacSign.taurus:
      'You project steadiness, warmth and reliability. Others sense your patience and groundedness from the first meeting. You have a calming presence that makes people feel safe and at ease.',
  ZodiacSign.gemini:
      'You appear curious, quick-witted and socially versatile. Others see your love of conversation and adaptability first. You can talk to anyone and seem to know a little about everything.',
  ZodiacSign.cancer:
      'You project nurturing sensitivity and quiet emotional intelligence. Others sense your empathy and protective instincts. You may seem shy at first, but your warmth draws people in once trust is established.',
  ZodiacSign.leo:
      'You radiate confidence, charisma and natural authority. Others notice your presence the moment you enter a room. You carry yourself with dignity and a warmth that makes people want to bask in your light.',
  ZodiacSign.virgo:
      'You appear thoughtful, precise and quietly capable. Others sense your reliability and sharp attention to detail. You project modesty, but your competence speaks for itself over time.',
  ZodiacSign.libra:
      'You come across as charming, diplomatic and aesthetically refined. Others see your ease in social situations and your genuine desire for harmony. You make people feel considered and respected.',
  ZodiacSign.scorpio:
      'You project intensity, magnetism and quiet power. Others sense there is more beneath the surface than you reveal. Your gaze is penetrating — you see what others miss, and people feel it.',
  ZodiacSign.sagittarius:
      'You appear enthusiastic, free-spirited and adventurous. Others see your optimism and philosophical openness. You draw people in with an infectious love of possibility and a frank honesty they find refreshing.',
  ZodiacSign.capricorn:
      'You project authority, competence and self-discipline. Others see someone reliable who has things handled. Your manner is professional, measured and quietly commanding — people trust you instinctively.',
  ZodiacSign.aquarius:
      'You appear original, independent and slightly unconventional. Others sense an intellectual depth and a refusal to conform. You stand apart from the crowd — and you seem completely comfortable doing so.',
  ZodiacSign.pisces:
      'You project a dreamy, gentle and deeply intuitive quality. Others sense your empathy and rich inner world immediately. You seem to absorb the mood of a room and reflect it back with compassion.',
};

// ── House modifier phrases ─────────────────────────────────────────────────────

const List<String> houseThemes = [
  'self, identity and first impressions',          // 1
  'resources, values and self-worth',              // 2
  'communication, learning and local connections', // 3
  'home, family and private foundations',          // 4
  'creativity, romance and self-expression',       // 5
  'health, work and daily service',                // 6
  'partnership, marriage and open relationships',  // 7
  'transformation, shared power and deep change',  // 8
  'philosophy, travel and expanding beliefs',      // 9
  'career, public reputation and authority',       // 10
  'community, friendships and collective ideals',  // 11
  'solitude, hidden matters and the unconscious',  // 12
];

// ── Planet-in-sign interpretations ────────────────────────────────────────────
// Indexed by ZodiacSign.index (0=Aries … 11=Pisces)

const Map<Planet, List<String>> planetInSign = {
  Planet.sun: [
    'Your identity is bold and pioneering — you lead with confidence and initiate without hesitation.',
    'Your sense of self is grounded and determined — you build your legacy through patience and tangible achievement.',
    'Your identity is defined by curiosity and versatility — you express yourself through ideas, communication and constant learning.',
    'Your core self is deeply nurturing — your sense of identity is tied to family, home and the instinct to protect those you love.',
    'You shine brightest when expressing yourself creatively and authentically — generosity and pride are central to who you are.',
    'Your identity is shaped by a desire to improve and serve — you apply precision to everything and hold yourself to high standards.',
    'You define yourself through relationships, fairness and the art of balance — harmony is both your strength and your ongoing pursuit.',
    'You pursue self-understanding relentlessly, transforming through every intense life experience — depth is your identity.',
    'Your sense of self is expansive and optimistic — freedom, philosophy and the pursuit of meaning drive your life\'s direction.',
    'You build your identity through structure, responsibility and long-term thinking — your legacy matters deeply to you.',
    'You identify as a forward-thinker who challenges convention — originality, independence and humanitarian vision define your core.',
    'Your identity dissolves boundaries — you absorb emotions and see beyond the material, driven by compassion and spiritual intuition.',
  ],
  Planet.moon: [
    'You process emotions through action and react quickly — you need independence and struggle with prolonged passivity.',
    'Your emotional nature is steady and comfort-seeking — you find peace through routine, loyalty and sensory pleasure.',
    'You process feelings through words and ideas — emotional needs shift quickly, and you are soothed by conversation and variety.',
    'Your feelings run deep and protective — home is your emotional anchor and you feel everything with intense sensitivity.',
    'You need recognition and warmth to feel emotionally stable — you thrive when appreciated and wilt when overlooked.',
    'You find comfort in order and usefulness — anxiety rises when things feel chaotic, and you calm yourself through productive doing.',
    'You yearn for harmony and emotional partnership — conflict and injustice leave you unsettled, and you need balanced relationships.',
    'Your emotional life is intense and private — you feel deeply but reveal little, using feeling as fuel for transformation.',
    'Your emotional wellbeing depends on freedom, adventure and philosophical perspective — you need space to feel at your best.',
    'You are emotionally reserved and self-controlled — you cope through action rather than feeling, and prefer results over processing.',
    'Your emotional nature is detached and unconventional — you need intellectual stimulation to feel satisfied and resist emotional smothering.',
    'Your feelings are boundless and empathic — you absorb others\' emotions easily and need regular solitude to recharge.',
  ],
  Planet.mercury: [
    'Your mind is fast and direct — you think in flashes and speak without filter, perfect for debate and decisive situations.',
    'Your thinking is deliberate and practical — you process slowly but thoroughly, arriving at conclusions that are solid and reliable.',
    'Your mind is quick and multi-tracked — you absorb information rapidly and excel at juggling multiple ideas simultaneously.',
    'Your thinking is intuitive and reflective — thoughts are shaped by emotion and memory, and you communicate with natural empathy.',
    'Your mind is dramatic and expressive — you communicate with confidence and flair, naturally drawing an audience.',
    'Your thinking is precise and analytical — your mind excels at detail, criticism and solving complex systematic problems.',
    'Your mind is fair and diplomatic — you weigh every angle before speaking, making you a skilled negotiator and mediator.',
    'Your thinking is probing and strategic — you see through surface information and communicate with purposeful, calculated depth.',
    'Your mind is expansive and direct — you think in broad pictures and sometimes skip steps that others find essential.',
    'Your thinking is structured and authoritative — you communicate with precision and your words carry practical, lasting weight.',
    'Your mind is innovative and contrarian — you think ahead of your time and approach problems with radical, original solutions.',
    'Your thinking is imaginative and associative — your mind wanders fluidly between ideas, guided more by intuition than logic.',
  ],
  Planet.venus: [
    'You love boldly and spontaneously — partnership must feel like an adventure, and you need excitement to stay engaged.',
    'You love through physical warmth and loyalty — consistency, comfort and lasting beauty matter more to you than novelty.',
    'Your love style is playful and communicative — stimulating conversation is essential, and you need variety to feel alive in love.',
    'You love with your whole heart and create deep emotional bonds — home and family are the centre of your romantic world.',
    'You love generously and dramatically — you give lavishly and expect to be adored as much as you adore.',
    'You show love through acts of service and careful attention — you improve everything in your partner\'s life, often quietly.',
    'You are charming and partnership-oriented — you thrive in relationships and have a refined eye for elegance and social harmony.',
    'You love with obsessive depth and demand total honesty and loyalty — it is all-or-nothing for you in matters of the heart.',
    'You love best when there is room to grow and philosophise together — freedom and shared ideals are non-negotiable.',
    'You take love seriously and are deeply devoted — commitment, stability and shared long-term goals mean everything to you.',
    'You prize intellectual connection and resist being caged — your love is unconventional, friendship-based and boundary-respecting.',
    'You love ideally and selflessly — sometimes to a fault, you dissolve into your partner\'s world and need to protect your boundaries.',
  ],
  Planet.mars: [
    'Your drive is raw and instinctive — you act on impulse, lead with force and thrive when you are breaking new ground.',
    'Your energy is slow, steady and ultimately unstoppable — once committed, you build momentum that nothing can derail.',
    'Your energy comes in bursts and you need mental variety — you excel when tasks shift and stimulate you intellectually.',
    'You fight hardest for those you love — your drive is emotionally motivated and protective rather than competitive.',
    'Your drive is bold and performance-oriented — you pour energy into recognition, creativity and anything that lets you lead.',
    'Your energy is precise and perfectionist — you direct effort toward improvement and can work tirelessly on the details.',
    'You pursue goals through negotiation and collaboration — your drive is strategic and people-oriented rather than forceful.',
    'Your drive is fierce and relentless — fuelled by depth and strategy, you pursue goals with surgical focus and intensity.',
    'Your energy is restless and optimistic — you charge toward distant horizons and quickly lose steam when confined.',
    'Your drive is disciplined and long-game oriented — your energy is best spent building systems and legacies that outlast you.',
    'Your energy is unpredictable and revolutionary — you fight for causes and inject sudden, disruptive momentum into stagnant systems.',
    'Your drive is fluid and spiritually motivated — subtle but powerful, inspired by compassion, creativity and a higher purpose.',
  ],
  Planet.jupiter: [
    'Your luck and growth expand through bold initiative and fearless leadership — fortune favours you when you act first.',
    'Your gifts unfold through patience, material abundance and deep sensory appreciation — slow-built fortune is the most enduring kind.',
    'You grow through intellectual exploration and versatile communication — knowledge opens every door for you.',
    'Your greatest good fortune flows through emotional intelligence, family bonds and following your intuition.',
    'Luck arrives when you shine without apology — creativity, generosity and authentic self-expression are your growth engines.',
    'Your biggest growth comes through service, meticulous excellence and improving the lives of those around you.',
    'Collaboration multiplies your reach — partnership, justice and aesthetic vision are the sources of your greatest reward.',
    'Your luck is found in what others overlook — transformation, deep research and hidden knowledge are your wells of fortune.',
    'You grow most when you explore beyond your comfort zone — philosophy, long-distance travel and higher learning expand your world.',
    'Your biggest wins come through patience, proven systems and long-term structural discipline.',
    'Your fortune is tied to collective progress — innovation, community-building and visionary thinking bring your greatest growth.',
    'Your greatest gifts flow from surrender to something greater than yourself — compassion, imagination and spiritual depth reward you.',
  ],
  Planet.saturn: [
    'You are here to develop courageous action that does not burn out — impulsiveness is your lesson, steadiness your reward.',
    'Real abundance comes through integrity and patience — you must build genuine security rather than cling to material possessions.',
    'You must master focus and depth over scattered curiosity — committing fully to one idea at a time is your greatest discipline.',
    'You are here to build emotional self-sufficiency and heal inherited family patterns — home is both your challenge and your prize.',
    'True leadership is earned through service, not ego — you must build recognition through real contribution, not performance.',
    'You must learn that good enough is sometimes enough — perfectionism that paralyses is the lesson Saturn sets before you.',
    'Honest partnerships built on truth rather than endless compromise are your path — justice requires difficult, uncomfortable honesty.',
    'Power, control and the ability to trust are your core lessons — your greatest growth comes from releasing what you cannot control.',
    'You must test your philosophies against lived experience — wisdom rooted in hard-won reality is the only kind that counts.',
    'You are here to build lasting structures with integrity — responsibility, legacy and disciplined effort are your true calling.',
    'You must balance revolutionary innovation with lasting contribution — reform without destruction is the discipline you are mastering.',
    'Your lesson is boundaries and spiritual discernment — you must learn to tell compassion from self-dissolution.',
  ],
  Planet.uranus: [
    'You disrupt cycles of inherited identity and pioneer radical personal reinvention — how you define "self" breaks all prior moulds.',
    'You revolutionise how resources and values are understood — your generation transforms what it means to own, earn and sustain.',
    'You rewire language, learning and the exchange of information — your generation changes how ideas travel and evolve.',
    'You break from traditional family structures and redefine what home and belonging mean for your generation.',
    'You disrupt how creativity and personal authenticity are celebrated — your generation reinvents what it means to be seen.',
    'You innovate in work, health and daily systems — your generation reorganises how service and efficiency function.',
    'You challenge traditional partnership and legal structures — your generation rewrites the rules of fairness in relationships.',
    'You expose and reinvent psychological and financial power structures — what is hidden gets brought to light by your generation.',
    'You dissolve dogma and inspire radically open thinking — your generation tears down borders between belief systems.',
    'You revolutionise how authority and institutions are structured — your generation dismantles what no longer serves society.',
    'You are technologically and socially ahead of your time — your generation advances what humanity is collectively capable of.',
    'You dissolve the boundaries between conscious and unconscious experience — your generation transforms spirituality and imagination.',
  ],
  Planet.neptune: [
    'Your idealism about identity can lead you to lose yourself — you are here to develop a sense of self that is real, not imagined.',
    'What truly satisfies you remains elusive — you are here to find beauty in simplicity and real value beneath the surface.',
    'Your mind is visionary but prone to drift — you must learn to ground your imaginative thinking in clear, communicable ideas.',
    'Your sense of home is deeply emotional and sometimes idealised — you are drawn to nostalgic memory and spiritual belonging.',
    'You are drawn to artistry, performance and spiritual creativity — your self-expression reaches for something transcendent.',
    'You sacrifice easily for others — thin boundaries in service and health mean you must actively protect your own wellbeing.',
    'You romanticise partnerships and must guard against disillusionment — real love is imperfect, and that is where the beauty lives.',
    'Your spiritual depth is profound and your psychic sensitivity high — you navigate transformation through inner knowing.',
    'You seek spiritual truth through philosophies that transcend the ordinary — your beliefs are expansive, visionary and ever-shifting.',
    'Your ideals challenge traditional institutions — you dream of structures built on higher principles rather than mere power.',
    'You dream of utopian community and universal belonging — your generation envisions a world without borders or exclusion.',
    'Your connection to the collective unconscious is profound — you are here to bridge the visible and the invisible.',
  ],
  Planet.pluto: [
    'You are reborn through radical personal reinvention — identity is never fixed for you; transformation is your natural state.',
    'You transform your relationship with security and material power — your generation redefines what it means to truly possess.',
    'You unearth hidden truths through relentless research and radical inquiry — your generation changes what we know and how we know it.',
    'Generational transformation begins in the private world — your generation heals or breaks inherited family and emotional patterns.',
    'You are drawn to deep transformation through authentic creation — your generation redefines what it means to express power.',
    'You purge what does not function and rebuild systems from the ground up — your generation transforms work and service.',
    'Your generation faces the shadow side of partnership and social contract — justice systems and relationships are rebuilt at depth.',
    'You embody Pluto\'s full force — intensity, rebirth, truth-seeking and radical transformation at every level of existence.',
    'You transform through destroying and rebuilding your entire worldview — belief systems are not inherited by your generation; they are earned.',
    'Your generation dismantles what no longer serves and forges new order — institutions are tested and rebuilt from their foundations.',
    'Your generation transforms how humanity organises and progresses — power structures and technology are permanently reshaped.',
    'Your transformation is deeply internal — your generation dissolves the barriers between the spiritual and the material.',
  ],
};
