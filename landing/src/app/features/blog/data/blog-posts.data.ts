export interface BlogPost {
    slug: string;
    title: string;
    excerpt: string;
    content: string;
    publishedAt: string;
    author: string;
    metaDescription: string;
    metaKeywords: string;
    ogImage?: string;
}

const BASE_URL = 'https://courthub.co';
const OG_IMAGE = `${BASE_URL}/images/og-image-1200x630.jpg`;

export const BLOG_POSTS: BlogPost[] = [
    {
        slug: 'monedero-digital-bi-financiero-eliminan-deudas-club-tenis-padel',
        title: 'Cómo el Monedero Digital y el BI Financiero eliminan las deudas en tu Club de Tenis y Padel',
        excerpt: 'Descubre cómo la integración con Wompi, el prepago en monedero y los reportes de BI te ayudan a eliminar deudas y tomar mejores decisiones de negocio en tu club.',
        metaDescription: 'Elimina deudas en tu club de tenis o padel con monedero digital Wompi y BI financiero. Prepago, reportes inteligentes y decisiones de negocio basadas en datos con CourtHub.',
        metaKeywords: 'monedero digital club tenis, BI financiero padel, Wompi pagos club, eliminar deudas club deportivo, reportes financieros tenis, CourtHub',
        publishedAt: '2026-02-05',
        author: 'CourtHub',
        ogImage: OG_IMAGE,
        content: `
            <p class="mb-6 text-gray-600 leading-relaxed">
                Si eres dueño de un club de tenis o pádel, sabes que una de las mayores pesadillas es el manejo de deudas: socios que deben meses, cobros pendientes que se acumulan y la dificultad de tener una visión clara de tu flujo de caja. <strong>CourtHub</strong> combina <strong>monedero digital</strong> e integración con <strong>Wompi</strong> con un <strong>BI financiero</strong> potente para que elimines las deudas de raíz y tomes decisiones de negocio con datos reales.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">El problema: deudas que crecen y cobros que no llegan</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                En clubes deportivos es común que los socios acumulen cuotas pendientes. Sin un sistema que obligue al prepago o que centralice los pagos, las deudas se vuelven inmanejables. Los reportes en Excel no bastan y pierdes visibilidad sobre qué servicios generan ingresos y cuáles solo gastos.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Solución 1: Monedero digital con prepago (integración Wompi)</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                CourtHub incluye un <strong>monedero digital</strong> integrado con <strong>Wompi</strong>, una de las pasarelas de pagos más confiables de Latinoamérica. La lógica es simple: los socios recargan saldo antes de consumir. Sin saldo, no hay consumo. Así reduces drásticamente las deudas porque el modelo cambia de "pago después" a "prepago".
            </p>
            <ul class="list-disc list-inside space-y-2 mb-6 text-gray-600 ml-4">
                <li><strong>Recargas instantáneas</strong> con tarjeta, PSE o transferencia vía Wompi</li>
                <li><strong>Uso de saldo</strong> para reservas, clases, tienda y consumos del club</li>
                <li><strong>Cero deudas por consumos</strong>: si no hay saldo, el sistema no permite el uso</li>
            </ul>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Solución 2: BI Financiero que muestra dónde está tu dinero</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                El <strong>BI financiero</strong> de CourtHub te ofrece reportes en tiempo real sobre ingresos, gastos, rentabilidad por servicio y penetración del monedero. Puedes ver qué canchas, qué profesores y qué productos generan más ingresos, y tomar decisiones basadas en datos, no en intuición.
            </p>
            <ul class="list-disc list-inside space-y-2 mb-6 text-gray-600 ml-4">
                <li><strong>Dashboard de ingresos</strong>: ingresos netos totales, tendencias y comparativas</li>
                <li><strong>Ahorro por monedero</strong>: cuánto ahorras al evitar cobros manuales y mora</li>
                <li><strong>Rentabilidad por servicio</strong>: qué canchas, clases o productos son más rentables</li>
            </ul>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Resultado: clubes sin deudas y con decisiones inteligentes</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                La combinación de <strong>monedero digital</strong> con <strong>Wompi</strong> y <strong>BI financiero</strong> permite a los clubes reducir a casi cero las deudas por consumos, automatizar cobros y tener una visión clara de su negocio. Si quieres llevar tu club al siguiente nivel con menos deudas y más control, CourtHub es la solución.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed">
                Solicita una demo y descubre cómo CourtHub puede transformar la gestión financiera de tu club de tenis o pádel.
            </p>
        `
    },
    {
        slug: 'reservas-no-llegan-caja-bi-financiero',
        title: '¿Por qué el 30% de las reservas de tu club no llegan a la caja? Evita fugas con BI Financiero',
        excerpt: 'Descubre las causas ocultas de las fugas de ingresos en reservas de canchas de padel y tenis, y cómo el software de gestión con BI Financiero te ayuda a auditarlas y recuperar rentabilidad.',
        metaDescription: 'Auditoría y control de reservas en clubes deportivos. Software de gestión con BI Financiero para detectar fugas de ingresos en canchas de padel y tenis. CourtHub.',
        metaKeywords: 'software de gestión club deportivo, BI financiero canchas padel, auditoría reservas tenis, fugas de ingresos club, CourtHub',
        publishedAt: '2026-02-06',
        author: 'CourtHub',
        ogImage: OG_IMAGE,
        content: `
            <p class="mb-6 text-gray-600 leading-relaxed">
                Si tienes un club de tenis o canchas de padel, es probable que una parte importante de tus reservas nunca se convierta en ingresos efectivos. No-show, cobros manuales que se olvidan, reservas sin pago confirmado: las fugas son silenciosas pero devastadoras para la rentabilidad. Un <strong>software de gestión</strong> con <strong>BI Financiero</strong> te permite auditar cada transacción y recuperar el control.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Las 3 fugas más comunes en reservas de canchas</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                En clubes deportivos, las reservas suelen escaparse por tres vías: no-show sin penalización, cobros en efectivo que no se registran en el sistema, y reservas hechas por WhatsApp o teléfono que nunca pasan por caja. Sin un <strong>software de gestión</strong> que trace cada reserva hasta el cobro, es imposible saber cuánto estás perdiendo.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Cómo el BI Financiero detecta las fugas</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                El <strong>BI Financiero</strong> de CourtHub cruza datos de reservas, cobros y uso real de canchas. Así identificas: reservas sin pago asociado, horarios bloqueados sin ingreso, y desfase entre lo reservado y lo cobrado. Los reportes por periodo (7, 30 y 90 días) te muestran tendencias y anomalías que un Excel nunca captaría.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Monedero Digital y Wompi: cerrar el ciclo de cobro</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Para que las reservas lleguen a la caja, el cobro debe ser previo. El <strong>monedero digital</strong> integrado con <strong>Wompi</strong> obliga a recargar antes de reservar. Sin saldo, no hay reserva. Esto elimina no-show y cobros pendientes, y todo queda registrado en el <strong>BI Financiero</strong> para auditoría en tiempo real.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed p-6 bg-gray-50 rounded-xl border-l-4 border-tenis-green">
                <strong>Caso de uso CourtHub:</strong> Un club con 8 canchas de padel detectó, gracias al dashboard de facturación, que el 28% de las reservas de fin de semana no tenían cobro asociado. Implementaron el monedero digital con Wompi y en 6 semanas redujeron esa fuga a menos del 2%. El reporte de rentabilidad por servicio les mostró exactamente qué horarios recuperaron ingresos.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed">
                Si quieres saber cuánto estás perdiendo en reservas que no llegan a la caja y cómo recuperarlo con auditoría y control, CourtHub te da la visibilidad que necesitas. Solicita una demo y empieza a cerrar fugas hoy.
            </p>
        `
    },
    {
        slug: 'padel-vs-tenis-mas-rentable-complejo-deportivo',
        title: 'Padel vs. Tenis: ¿Cuál es el deporte más rentable para tu complejo deportivo?',
        excerpt: 'Comparativa de rentabilidad entre canchas de padel y tenis. Descubre con BI Financiero qué deporte genera más ingresos y atrae mejor a inversionistas de clubes.',
        metaDescription: 'Padel vs tenis: rentabilidad en complejos deportivos. BI Financiero para comparar ingresos por cancha. Software de gestión para clubes de raqueta. CourtHub.',
        metaKeywords: 'canchas de padel rentabilidad, tenis vs padel negocio, complejo deportivo inversión, BI financiero club, software gestión club, CourtHub',
        publishedAt: '2026-02-07',
        author: 'CourtHub',
        ogImage: OG_IMAGE,
        content: `
            <p class="mb-6 text-gray-600 leading-relaxed">
                Si eres dueño de un complejo deportivo o estás evaluando invertir en uno, la pregunta es inevitable: ¿padel o tenis? La respuesta no es única, pero con un <strong>software de gestión</strong> y <strong>BI Financiero</strong> puedes medir con precisión qué deporte aporta más a tu rentabilidad y presentar datos sólidos a inversionistas.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Variables que definen la rentabilidad por deporte</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                La rentabilidad de las <strong>canchas de padel</strong> vs. tenis depende del costo por m², la rotación (partidos por hora), el precio por hora, y los ingresos adicionales (clases, torneos, tienda). Sin datos consolidados, las decisiones se toman por intuición. El <strong>BI Financiero</strong> te permite comparar ingresos netos, ocupación y ticket promedio por tipo de cancha.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Qué dicen los reportes de CourtHub</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                CourtHub segmenta la rentabilidad por servicio: alquiler de pistas, clases, torneos, consumos. Así ves si las canchas de padel generan más por hora que las de tenis, o si las clases de tenis compensan una menor rotación. El dashboard de ingresos te muestra tendencias en 7, 30 y 90 días para planificar inversiones.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Datos que atraen a inversionistas</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Los inversionistas de clubes quieren ver métricas claras: margen por cancha, proyección de ingresos, penetración del <strong>monedero digital</strong> y ahorro en comisiones. CourtHub te entrega reportes ejecutivos listos para presentar: rentabilidad por servicio, ahorro por monedero y penetración de pagos vía <strong>Wompi</strong>. Información profesional que genera confianza.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed p-6 bg-gray-50 rounded-xl border-l-4 border-tenis-green">
                <strong>Caso de uso CourtHub:</strong> Un complejo con 4 pistas de tenis y 6 de padel usó el desglose ejecutivo para descubrir que, aunque el padel tenía mayor ocupación, las clases de tenis generaban un ticket promedio 40% superior. Ajustaron su oferta y aumentaron los ingresos netos en 22% en un trimestre. Los reportes de BI Financiero fueron clave para la decisión.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed">
                No adivines: mide. Con CourtHub obtienes la visibilidad financiera para decidir qué deporte priorizar y cómo argumentar ante inversionistas. Solicita una demo y descubre la rentabilidad real de tu complejo deportivo.
            </p>
        `
    },
    {
        slug: 'guia-pagos-automaticos-wompi-canchas-raqueta',
        title: 'La guía definitiva para implementar pagos automáticos con Wompi en canchas de raqueta',
        excerpt: 'Pasos técnicos y operativos para automatizar cobros con Wompi en tu club de tenis o padel. Monedero digital, BI Financiero y software de gestión integrados.',
        metaDescription: 'Implementar pagos automáticos con Wompi en canchas de raqueta. Guía técnica para clubes de tenis y padel. Monedero digital y software de gestión CourtHub.',
        metaKeywords: 'Wompi pagos club deportivo, pagos automáticos canchas padel, monedero digital tenis, software gestión cobros, CourtHub',
        publishedAt: '2026-02-08',
        author: 'CourtHub',
        ogImage: OG_IMAGE,
        content: `
            <p class="mb-6 text-gray-600 leading-relaxed">
                Cobrar en efectivo, anotar en cuaderno o depender de transferencias manuales ya no es sostenible. La automatización de pagos con <strong>Wompi</strong> en tu club de tenis o canchas de padel reduce errores, acelera la cobranza y mejora la experiencia de tus socios. Esta guía te explica cómo hacerlo con un <strong>software de gestión</strong> que integra todo.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Por qué Wompi es ideal para clubes de raqueta</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                <strong>Wompi</strong> es una pasarela de pagos con presencia en Latinoamérica que acepta tarjetas, PSE y transferencias. Para clubes deportivos, la ventaja es la integración con un <strong>monedero digital</strong>: los socios recargan una vez y consumen en reservas, clases y tienda sin fricción. El cobro es automático y queda registrado para el <strong>BI Financiero</strong>.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Pasos para implementar pagos automáticos</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Primero, tu <strong>software de gestión</strong> debe integrar Wompi de forma nativa. CourtHub lo hace: activas el monedero digital, configuras los productos (reservas, clases, consumos) y los socios recargan desde la app. Segundo, defines cobros recurrentes para cuotas de membresía. Tercero, el <strong>BI Financiero</strong> te da visibilidad de ingresos, conciliación y ahorro en comisiones.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Conciliación y reportes en tiempo real</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Sin automatización, conciliar cobros manualmente es un caos. Con CourtHub y Wompi, cada transacción se registra automáticamente. El dashboard de facturación muestra ingresos netos, ahorro por monedero y penetración de pagos electrónicos. Reportes de 7, 30 y 90 días te permiten auditar y planificar con datos reales.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed p-6 bg-gray-50 rounded-xl border-l-4 border-tenis-green">
                <strong>Caso de uso CourtHub:</strong> Un club con 6 canchas de padel migró de cobro manual a pagos automáticos con Wompi en 3 semanas. El monedero digital pasó a ser obligatorio para reservar. El resultado: reducción del 95% en cobros pendientes, ahorro de 15 horas semanales en administración, y un reporte de BI Financiero que mostraba un ahorro del 3% en comisiones frente al cobro con POS tradicional.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed">
                Automatizar cobros en tu club de tenis o padel no tiene por qué ser complejo. CourtHub integra Wompi, monedero digital y BI Financiero en una sola plataforma. Solicita una demo y comienza a cobrar sin fricción.
            </p>
        `
    },
    {
        slug: 'rankings-elo-retencion-alumnos-academia-tenis',
        title: 'Cómo los rankings ELO aumentan la retención de tus alumnos en la academia de tenis',
        excerpt: 'La gamificación con rankings ELO mejora la retención en academias de tenis y padel. Descubre cómo CourtHub combina rankings, monedero digital y BI para fidelizar alumnos.',
        metaDescription: 'Rankings ELO en academia de tenis para retener alumnos. Gamificación y fidelización en clubes deportivos. Software de gestión CourtHub.',
        metaKeywords: 'ranking ELO tenis, retención alumnos academia, gamificación club deportivo, fidelización padel, software gestión CourtHub',
        publishedAt: '2026-02-09',
        author: 'CourtHub',
        ogImage: OG_IMAGE,
        content: `
            <p class="mb-6 text-gray-600 leading-relaxed">
                Las academias de tenis y padel viven de la recurrencia: alumnos que vuelven semana a semana. El problema es la fuga: falta de motivación, sensación de estancamiento, competencia con otras opciones. Los <strong>rankings ELO</strong> convierten el progreso en algo visible y competitivo, aumentando la retención. Un <strong>software de gestión</strong> como CourtHub los integra con tu operación y tu <strong>BI Financiero</strong>.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Por qué el ELO funciona en academias deportivas</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                El sistema ELO asigna puntos según resultados de partidos: ganas, subes; pierdes, bajas. Es justo, transparente y crea una meta clara: mejorar el ranking. En una academia de tenis o padel, esto motiva a los alumnos a seguir jugando, inscribirse en torneos y recomendar el club. La gamificación reduce la rotación y aumenta el lifetime value.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Integración con monedero digital y reservas</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Para que el ELO impacte la rentabilidad, debe estar ligado al uso real del club. CourtHub conecta el ranking con reservas, clases y torneos. Los alumnos pagan con <strong>monedero digital</strong> (vía <strong>Wompi</strong>), reservan canchas, y el sistema actualiza el ELO automáticamente. El <strong>BI Financiero</strong> te muestra la correlación entre actividad en rankings y aumento de consumos.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Reportes de penetración y retención</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                CourtHub te permite medir el impacto: penetración del monedero entre alumnos que participan en rankings, frecuencia de reservas antes y después de activar ELO, y rentabilidad por servicio (clases vs. torneos). Los datos del <strong>BI Financiero</strong> te ayudan a optimizar torneos, premios y comunicaciones para maximizar la retención.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed p-6 bg-gray-50 rounded-xl border-l-4 border-tenis-green">
                <strong>Caso de uso CourtHub:</strong> Una academia de tenis con 120 alumnos activó el ranking ELO integrado con reservas y monedero digital. En 3 meses, la retención mensual pasó del 72% al 89%. El reporte de rentabilidad por servicio mostró un aumento del 34% en reservas de canchas entre alumnos que competían en el ranking. El dashboard de penetración de monedero reflejó que el 85% de los jugadores activos en ELO ya pagaban con saldo digital.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed">
                Los rankings ELO no son solo entretenimiento: son una herramienta de fidelización que, bien integrada con pagos y datos, aumenta la rentabilidad de tu academia. CourtHub une ELO, monedero digital y BI Financiero en una sola plataforma. Solicita una demo y empieza a retener más alumnos.
            </p>
        `
    },
    {
        slug: 'gestion-deudas-pago-anticipado-monedero-digital',
        title: "Gestión de deudas: Cómo pasar del 'te pago luego' al pago anticipado con Monedero Digital",
        excerpt: "Transforma el flujo de caja de tu club: de cobros pendientes y mora a un modelo de prepago con monedero digital. Wompi y BI Financiero para eliminar el 'te pago luego'.",
        metaDescription: "Gestión de deudas en clubes deportivos. Pasar de 'te pago luego' a pago anticipado con monedero digital. Wompi, BI Financiero y CourtHub.",
        metaKeywords: 'gestión deudas club deportivo, monedero digital prepago, flujo de caja canchas padel, Wompi pagos, BI financiero, CourtHub',
        publishedAt: '2026-02-10',
        author: 'CourtHub',
        ogImage: OG_IMAGE,
        content: `
            <p class="mb-6 text-gray-600 leading-relaxed">
                "Te pago luego" es la frase que más dueño de club de tenis o canchas de padel ha escuchado. Las deudas se acumulan, la mora crece y el flujo de caja se resiente. La solución no es cobrar más fuerte, sino cambiar el modelo: pasar al <strong>pago anticipado</strong> con <strong>monedero digital</strong>. CourtHub lo hace posible con integración <strong>Wompi</strong> y <strong>BI Financiero</strong> para controlar cada peso.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">El costo oculto del 'te pago luego'</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Cuando permitir crédito se convierte en norma, aparecen las deudas incobrables, el tiempo perdido en recordatorios y la incertidumbre del flujo de caja. Un <strong>software de gestión</strong> con visión financiera te muestra cuánto tienes en cartera vencida y qué porcentaje nunca se recupera. El <strong>BI Financiero</strong> de CourtHub pone números a un problema que muchos prefieren ignorar.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">Monedero digital: sin saldo, no hay consumo</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                El <strong>monedero digital</strong> invierte la lógica: primero se recarga, después se consume. Integrado con <strong>Wompi</strong>, los socios pagan con tarjeta, PSE o transferencia; el saldo se acredita al instante y se usa en reservas, clases, tienda. Cero deudas por consumos: si no hay saldo, el sistema no permite la reserva. El flujo de caja mejora porque el dinero entra antes de que se preste el servicio.
            </p>

            <h2 class="text-2xl font-bold text-tenis-dark mt-10 mb-4">BI Financiero: visibilidad del flujo de caja</h2>
            <p class="mb-6 text-gray-600 leading-relaxed">
                Con el modelo de prepago, el <strong>BI Financiero</strong> te muestra ingresos netos en tiempo real, ahorro por monedero (menos cobros manuales, menos mora) y penetración del monedero entre socios. Reportes de 7, 30 y 90 días te permiten proyectar flujo de caja con precisión. Ya no dependes de "quién te debe" sino de "cuánto tienes disponible".
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed p-6 bg-gray-50 rounded-xl border-l-4 border-tenis-green">
                <strong>Caso de uso CourtHub:</strong> Un club con 200 socios tenía un 18% de cartera vencida y dedicaba 20 horas al mes a cobranza. Tras implementar el monedero digital con Wompi y hacerlo obligatorio para reservas y clases, la cartera vencida bajó al 2% en 8 semanas. El reporte de BI Financiero mostró un ahorro de $1.800/mes en comisiones bancarias y 15 horas mensuales recuperadas en administración.
            </p>

            <p class="mb-6 text-gray-600 leading-relaxed">
                Pasar del "te pago luego" al pago anticipado no es solo operativo: es estratégico para la salud financiera de tu club. CourtHub te da el monedero digital, la integración Wompi y el BI Financiero para hacerlo sin fricción. Solicita una demo y transforma tu flujo de caja hoy.
            </p>
        `
    }
];

export const getBlogPostBySlug = (slug: string): BlogPost | undefined =>
    BLOG_POSTS.find((post) => post.slug === slug);

export const getAllBlogSlugs = (): string[] =>
    BLOG_POSTS.map((post) => post.slug);
