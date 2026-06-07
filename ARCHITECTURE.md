# InvestMatch — Arquitectura del Proyecto

**Desarrollado por:** Carolina Chalabe y Felipe Romero  
**Stack:** Flutter (Dart) + NestJS + PostgreSQL  
**Versión MVP:** 1.0.0

---

## Estructura del proyecto Flutter

```
lib/
├── main.dart                          # Entry point, Firebase init, Riverpod
├── core/
│   ├── constants/app_constants.dart   # Constantes globales (roles, etapas, verticales, etc.)
│   ├── router/app_router.dart         # go_router: rutas protegidas + shell navigation
│   └── theme/app_theme.dart           # Design system (colores, tipografía, componentes)
├── shared/
│   ├── models/
│   │   ├── user_model.dart            # UserModel, InvestorProfile, FounderProfile
│   │   ├── project_model.dart         # ProjectModel, ProjectMetrics, PipelineEntry
│   │   └── message_model.dart         # MessageModel, ConversationModel, MeetingModel
│   └── services/
│       ├── api_service.dart           # Todos los endpoints REST (Dio + interceptores JWT)
│       ├── auth_service.dart          # Login, registro, Google Sign-In, logout
│       └── notification_service.dart  # FCM + APNs + notificaciones locales
└── features/
    ├── auth/                          # Splash, Login, Register + AuthNotifier (Riverpod)
    ├── kyc/                           # Flujo KYC: DNI frente/dorso + selfie liveness
    ├── home/                          # Dashboard diferenciado inversor/emprendedor
    ├── search/                        # Búsqueda avanzada con 5 filtros + bottom sheet
    ├── projects/                      # CRUD proyectos, detalle, creación paso a paso
    ├── messaging/                     # Chat WebSocket + lista de conversaciones
    ├── pipeline/                      # Kanban de inversión (7 etapas) solo para inversores
    ├── analytics/                     # Dashboard métricas para emprendedores + gráficos
    ├── agenda/                        # Calendario TableCalendar + agendar reuniones
    ├── payments/                      # Planes Free/Pro/Enterprise + checkout Mercado Pago
    └── profile/                       # Perfil, edición, configuración, logout
```

---

## Stack tecnológico

| Capa | Tecnología | Por qué |
|------|-----------|---------|
| Frontend móvil | Flutter 3.x + Dart | Un codebase para iOS+Android, rendimiento cercano a nativo |
| Estado global | Riverpod 2.x | Type-safe, testable, sin boilerplate |
| Navegación | go_router | Deep links, rutas protegidas, shell navigation |
| HTTP client | Dio | Interceptores para JWT refresh automático |
| Base de datos local | Flutter Secure Storage + Hive | Tokens seguros + caché offline |
| Push notifications | Firebase Cloud Messaging (FCM) + APNs | Cobertura completa iOS/Android |
| Chat real-time | Socket.IO client | Baja latencia, presencia, typing indicators |
| Pagos | Mercado Pago checkout (web redirect) | Mayor adopción en Argentina |
| Analytics | Firebase Analytics | Gratuito, funnels, cohorts |
| Calendario | table_calendar | Componente nativo Flutter |
| Gráficos | fl_chart | Charts declarativos Flutter |

---

## Backend (NestJS) — estructura sugerida

```
src/
├── auth/          # JWT + refresh tokens + Google OAuth + Apple Sign-In
├── users/         # CRUD usuarios, perfiles, KYC status
├── projects/      # CRUD proyectos, imágenes, pitch deck, analytics
├── matching/      # Algoritmo de match por preferencias
├── messaging/     # WebSocket gateway + persistencia mensajes
├── meetings/      # Agenda, CRUD reuniones
├── pipeline/      # Pipeline de inversión por inversor
├── payments/      # Mercado Pago webhooks, suscripciones, idempotencia
├── notifications/ # FCM/APNs token registration, envío de push
└── moderation/    # Reportes, ban, filtros anti-spam
```

---

## Roles de usuario (RBAC)

| Rol | Permisos |
|-----|---------|
| `founder` | Crear/editar proyectos, ver analytics propios, responder mensajes |
| `investor` | Buscar proyectos, pipeline, contactar founders, agendar meetings |
| `admin` | Panel admin, ban usuarios, moderar contenido |
| `moderator` | Revisar reportes, banear contenido |

---

## Flujo KYC/KYB

1. Usuario se registra → `kycStatus: pending`
2. Sube DNI frente + dorso + selfie liveness
3. Backend envía a proveedor (Onfido/Sumsub) o revisión manual
4. Admin aprueba → `kycStatus: verified`
5. Usuario obtiene badge verificado ✓

---

## Pipeline de inversión (solo inversores)

```
Descubierto → Contactado → Evaluando → Reunido → Due Diligence → Cerrado/Rechazado
```

---

## Seguridad implementada

- JWT de corta vida (15min) + Refresh tokens seguros (HTTPOnly en web)
- Auto-refresh de tokens con Dio interceptor
- Almacenamiento de tokens en Flutter Secure Storage (KeyStore/Keychain)
- RBAC en backend + guards en rutas Flutter
- Reporte y moderación de usuarios/proyectos
- Cumplimiento Ley 25.326 (datos personales, consentimiento, baja de datos)

---

## Pagos (Mercado Pago)

- Suscripción mensual/anual: Free / Pro ($9.990/mes) / Enterprise ($24.990/mes)
- Proyectos destacados: pago one-off
- Fee de éxito: manual, acordado entre partes
- Webhook confiable + idempotencia en backend

---

## Roadmap MVP (12–16 semanas)

| Semana | Hito |
|--------|------|
| 1–2 | Discovery + UX + Setup repo/CI/CD/design system |
| 3–5 | Auth + KYC + perfiles + CRUD proyectos |
| 6–7 | Búsqueda + filtros + pipeline + favoritos |
| 8–9 | Mensajería WebSocket + push notifications |
| 10 | Analytics + moderación + reportes |
| 11–12 | Pagos (Mercado Pago) + planes |
| 13–14 | QA + accesibilidad + seguridad hardening |
| 15–16 | Beta cerrada → publicación App Store / Google Play |
