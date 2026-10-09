import type { Metadata } from "next";
import Link from "next/link";
import styles from "./page.module.css";

export const metadata: Metadata = {
  title: "Planos | Kingdom",
  description:
    "Conheça os planos propostos do Kingdom para organizar a gestão da sua igreja.",
};

const plans = [
  {
    name: "Essencial",
    description: "O começo organizado para cuidar das informações da comunidade.",
    features: [
      "Cadastro e consulta de membros",
      "Organização de grupos e ministérios",
      "Acesso para a equipe administrativa",
    ],
  },
  {
    name: "Crescimento",
    description: "Mais recursos para acompanhar a rotina e aproximar pessoas.",
    featured: true,
    features: [
      "Tudo do plano Essencial",
      "Organização de eventos e atividades",
      "Acompanhamento de presença",
      "Relatórios para apoiar decisões",
    ],
  },
  {
    name: "Completo",
    description: "Uma visão integrada para as diferentes áreas da igreja.",
    features: [
      "Tudo do plano Crescimento",
      "Gestão financeira e contribuições",
      "Perfis de acesso por função",
      "Acompanhamento administrativo ampliado",
    ],
  },
];

const addOns = [
  {
    number: "01",
    title: "Módulos sob medida",
    description:
      "Escolha recursos adicionais de acordo com as necessidades da sua igreja.",
  },
  {
    number: "02",
    title: "Acesso para a equipe",
    description:
      "Organize quem pode consultar e administrar as informações da comunidade.",
  },
  {
    number: "03",
    title: "Acompanhamento próximo",
    description:
      "Uma implantação pensada para a realidade e o ritmo da sua igreja.",
  },
];

export default function PlansPage() {
  return (
    <main className={styles.page}>
      <header className={styles.header}>
        <Link aria-label="Kingdom - página inicial" className={styles.brand} href="/">
          <span aria-hidden="true" className={styles.brandMark}>
            K
          </span>
          <span>ingdom</span>
        </Link>

        <nav aria-label="Navegação principal" className={styles.nav}>
          <a href="#beneficios">Benefícios</a>
          <a href="#planos">Planos</a>
          <a href="#perguntas">Dúvidas</a>
        </nav>

        <Link className={styles.loginLink} href="/login">
          Acessar minha conta <span aria-hidden="true">↗</span>
        </Link>
      </header>

      <section aria-labelledby="hero-title" className={styles.hero}>
        <div className={styles.heroCopy}>
          <p className={styles.eyebrow}>
            <span aria-hidden="true" className={styles.eyebrowDot} />
            Gestão feita para servir
          </p>
          <h1 id="hero-title">
            Mais tempo para cuidar.
            <br />
            <span>Menos tempo organizando.</span>
          </h1>
          <p className={styles.heroDescription}>
            Uma forma mais simples de reunir as informações e a rotina da sua
            igreja — com espaço para crescer junto com a comunidade.
          </p>
          <div className={styles.heroActions}>
            <a className={styles.primaryButton} href="#planos">
              Conheça os planos <span aria-hidden="true">↓</span>
            </a>
            <a className={styles.textButton} href="#beneficios">
              Descubra como funciona <span aria-hidden="true">→</span>
            </a>
          </div>
          <div className={styles.heroNote}>
            <span aria-hidden="true" className={styles.noteIcon}>
              ✳
            </span>
            <p>
              Uma proposta flexível para igrejas de diferentes tamanhos e
              momentos.
            </p>
          </div>
        </div>

        <div aria-hidden="true" className={styles.heroVisual}>
          <div className={styles.visualGlow} />
          <div className={styles.visualCard}>
            <div className={styles.visualCardTop}>
              <span className={styles.visualCaption}>VISÃO DA COMUNIDADE</span>
              <span className={styles.liveDot} />
            </div>
            <div className={styles.visualTitle}>Cuidar é estar presente.</div>
            <div className={styles.visualLine} />
            <div className={styles.visualRows}>
              <div className={styles.visualRow}>
                <span className={styles.rowIcon}>01</span>
                <span>
                  <b>Pessoas</b>
                  <small>Uma comunidade, muitas histórias</small>
                </span>
                <span className={styles.rowArrow}>↗</span>
              </div>
              <div className={styles.visualRow}>
                <span className={`${styles.rowIcon} ${styles.rowIconWarm}`}>
                  02
                </span>
                <span>
                  <b>Encontros</b>
                  <small>Momentos que aproximam</small>
                </span>
                <span className={styles.rowArrow}>↗</span>
              </div>
              <div className={styles.visualRow}>
                <span className={`${styles.rowIcon} ${styles.rowIconBlue}`}>
                  03
                </span>
                <span>
                  <b>Serviço</b>
                  <small>Talentos a favor de todos</small>
                </span>
                <span className={styles.rowArrow}>↗</span>
              </div>
            </div>
            <div className={styles.visualFooter}>
              <span>Comunidade</span>
              <span className={styles.footerPills}>
                <i />
                <i />
                <i />
                <i />
              </span>
              <span>em movimento</span>
            </div>
          </div>
          <div className={styles.floatingNote}>
            <span className={styles.floatingIcon}>✦</span>
            <span>
              <b>Mais organização</b>
              <small>para o que realmente importa</small>
            </span>
          </div>
          <div className={styles.visualStamp}>COMUNIDADE<br />EM PRIMEIRO LUGAR</div>
        </div>

        <a aria-label="Veja os benefícios" className={styles.scrollCue} href="#beneficios">
          <span />
        </a>
      </section>

      <section aria-labelledby="benefits-title" className={styles.benefits} id="beneficios">
        <div className={styles.sectionIntro}>
          <p className={styles.eyebrow}>Organização com propósito</p>
          <h2 id="benefits-title">
            A tecnologia cuida dos detalhes.
            <br />
            <span>Você cuida das pessoas.</span>
          </h2>
        </div>
        <div className={styles.benefitGrid}>
          <article className={styles.benefitCard}>
            <span className={styles.benefitNumber}>01 / CENTRALIZE</span>
            <h3>Tudo no seu lugar</h3>
            <p>
              Reúna informações importantes para que sua equipe encontre o que
              precisa com mais facilidade.
            </p>
            <span aria-hidden="true" className={styles.benefitArrow}>↗</span>
          </article>
          <article className={styles.benefitCard}>
            <span className={styles.benefitNumber}>02 / SIMPLIFIQUE</span>
            <h3>Rotina mais leve</h3>
            <p>
              Organize tarefas e atividades da igreja sem perder de vista o
              cuidado com cada pessoa.
            </p>
            <span aria-hidden="true" className={styles.benefitArrow}>↗</span>
          </article>
          <article className={styles.benefitCard}>
            <span className={styles.benefitNumber}>03 / CRESÇA</span>
            <h3>Do seu jeito</h3>
            <p>
              Comece pelo essencial e considere novos recursos conforme a
              comunidade evolui.
            </p>
            <span aria-hidden="true" className={styles.benefitArrow}>↗</span>
          </article>
        </div>
      </section>

      <section aria-labelledby="plans-title" className={styles.plansSection} id="planos">
        <div className={styles.plansHeader}>
          <div>
            <p className={styles.eyebrow}>Um plano para cada jornada</p>
            <h2 id="plans-title">
              Escolha como <span>quer crescer.</span>
            </h2>
          </div>
          <p>
            Comece com o que sua igreja precisa hoje. Os módulos e as condições
            podem ser definidos de acordo com a sua realidade.
          </p>
        </div>

        <div className={styles.planGrid}>
          {plans.map((plan, index) => (
            <article
              className={`${styles.planCard} ${plan.featured ? styles.featuredPlan : ""}`}
              key={plan.name}
            >
              {plan.featured && <span className={styles.popularLabel}>MAIS ESCOLHIDO</span>}
              <div className={styles.planTopline}>
                <span className={styles.planIndex}>0{index + 1}</span>
                <span className={styles.planStatus}>PLANO PROPOSTO</span>
              </div>
              <h3>{plan.name}</h3>
              <p className={styles.planDescription}>{plan.description}</p>
              <div className={styles.price}>
                <span className={styles.priceValue}>Sob consulta</span>
                <span className={styles.priceCaption}>condições personalizadas</span>
              </div>
              <a className={styles.planButton} href="#como-contratar">
                Tenho interesse <span aria-hidden="true">↗</span>
              </a>
              <div className={styles.planDivider} />
              <p className={styles.featuresLabel}>O que pode incluir</p>
              <ul className={styles.featureList}>
                {plan.features.map((feature) => (
                  <li key={feature}>
                    <span aria-hidden="true">✓</span> {feature}
                  </li>
                ))}
              </ul>
            </article>
          ))}
        </div>
        <p className={styles.planDisclaimer}>
          Os planos acima representam uma proposta de organização dos recursos.
          Disponibilidade, valores e funcionalidades serão confirmados com a
          equipe responsável.
        </p>
      </section>

      <section aria-labelledby="add-ons-title" className={styles.addOnsSection}>
        <div className={styles.addOnsIntro}>
          <p className={styles.eyebrow}>Mais possibilidades</p>
          <h2 id="add-ons-title">
            Sua igreja é única.
            <br />
            <span>Seu plano também pode ser.</span>
          </h2>
          <p>
            Além dos níveis de acesso, a proposta pode considerar módulos
            adicionais e o suporte que faz sentido para a sua equipe.
          </p>
        </div>
        <div className={styles.addOnList}>
          {addOns.map((item) => (
            <article className={styles.addOn} key={item.number}>
              <span className={styles.addOnNumber}>{item.number}</span>
              <div>
                <h3>{item.title}</h3>
                <p>{item.description}</p>
              </div>
              <span aria-hidden="true" className={styles.addOnArrow}>↗</span>
            </article>
          ))}
        </div>
      </section>

      <section aria-labelledby="faq-title" className={styles.faqSection} id="perguntas">
        <div className={styles.faqHeading}>
          <p className={styles.eyebrow}>Antes de começar</p>
          <h2 id="faq-title">Dúvidas frequentes</h2>
        </div>
        <div className={styles.faqList}>
          <details>
            <summary>Como escolho o plano ideal para minha igreja?</summary>
            <p>
              Considere quais áreas deseja organizar primeiro. A equipe
              responsável poderá ajudar a avaliar os recursos e as condições
              adequados à realidade da sua igreja.
            </p>
          </details>
          <details>
            <summary>Posso contratar módulos individualmente?</summary>
            <p>
              A proposta prevê módulos adicionais. A disponibilidade e as
              condições de contratação devem ser confirmadas com a equipe
              responsável.
            </p>
          </details>
          <details>
            <summary>O sistema já está disponível para contratação?</summary>
            <p>
              O Kingdom está em desenvolvimento. Os planos desta página são
              uma proposta e não representam confirmação de disponibilidade
              comercial ou de recursos já implantados.
            </p>
          </details>
        </div>
      </section>

      <section aria-labelledby="contact-title" className={styles.contactSection} id="como-contratar">
        <div className={styles.contactDecor} aria-hidden="true">✳</div>
        <p className={styles.eyebrow}>Vamos conversar?</p>
        <h2 id="contact-title">
          O próximo passo começa
          <br />
          <span>com uma boa conversa.</span>
        </h2>
        <p>
          Quer saber mais sobre os planos? Entre em contato com a pessoa ou
          equipe que compartilhou este link para confirmar recursos, valores e
          disponibilidade.
        </p>
        <Link className={styles.contactButton} href="/login">
          Já sou cliente <span aria-hidden="true">↗</span>
        </Link>
        <span className={styles.contactFootnote}>
          Contratação e pagamento online ainda não estão disponíveis.
        </span>
      </section>

      <footer className={styles.footer}>
        <Link aria-label="Kingdom - página inicial" className={styles.brand} href="/">
          <span aria-hidden="true" className={styles.brandMark}>K</span>
          <span>ingdom</span>
        </Link>
        <span>Feito para cuidar melhor de quem cuida.</span>
        <Link className={styles.footerLogin} href="/login">Acessar sistema ↗</Link>
      </footer>
    </main>
  );
}
