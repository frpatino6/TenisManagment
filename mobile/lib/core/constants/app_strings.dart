/// Centralized application strings
///
/// All user-facing strings should be defined here for:
/// - Consistency across the app
/// - Easy modification
/// - Future internationalization (i18n) support
///
/// Note: Error messages are in `error_messages.dart`
class AppStrings {
  AppStrings._();

  // ============================================
  // Common Actions
  // ============================================
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String confirm = 'Confirmar';
  static const String retry = 'Reintentar';
  static const String close = 'Cerrar';
  static const String back = 'Volver';
  static const String next = 'Siguiente';
  static const String previous = 'Anterior';
  static const String search = 'Buscar';
  static const String filter = 'Filtrar';
  static const String clear = 'Limpiar';
  static const String apply = 'Aplicar';
  static const String reset = 'Restablecer';
  static const String submit = 'Enviar';
  static const String loading = 'Cargando...';
  static const String processing = 'Procesando...';
  static const String success = 'Éxito';
  static const String error = 'Error';

  // ============================================
  // Authentication
  // ============================================
  static const String login = 'Iniciar Sesión';
  static const String logout = 'Cerrar Sesión';
  static const String register = 'Registrarse';
  static const String email = 'Email';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar Contraseña';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String rememberMe = 'Recordarme';
  static const String loginWithGoogle = 'Continuar con Google';
  static const String dontHaveAccount = '¿No tienes cuenta?';
  static const String alreadyHaveAccount = '¿Ya tienes cuenta?';
  static const String verifyingAuth = 'Verificando autenticación...';

  // ============================================
  // Navigation & Titles
  // ============================================
  static const String home = 'Inicio';
  static const String dashboard = 'Panel';
  static const String profile = 'Perfil';
  static const String settings = 'Configuración';
  static const String schedule = 'Horario';
  static const String schedules = 'Horarios';
  static const String bookings = 'Reservas';
  static const String students = 'Estudiantes';
  static const String professors = 'Profesores';
  static const String courts = 'Canchas';
  static const String analytics = 'Analíticas';
  static const String earnings = 'Ganancias';

  // ============================================
  // Professor
  // ============================================
  static const String professorPanel = 'Panel del Profesor';
  static const String welcomeProfessor = '¡Bienvenido, {name}!';
  static const String createSchedule = 'Crear Horario Disponible';
  static const String manageSchedules = 'Gestionar Horarios';
  static const String mySchedules = 'Mis Horarios';
  static const String todaySchedule = 'Horario de Hoy';
  static const String weekSchedule = 'Horario de la Semana';
  static const String defineAvailability = 'Define tu disponibilidad';
  static const String viewMySchedules = 'Ver mis horarios';
  static const String professorInfo = 'Información del Profesor';
  static const String updateProfile = 'Actualizar Perfil';

  // ============================================
  // Student
  // ============================================
  static const String studentPanel = 'Panel del Estudiante';
  static const String myBookings = 'Mis Reservas';
  static const String recentActivity = 'Actividad Reciente';
  static const String myBalance = 'Mi Saldo';
  static const String requestService = 'Solicitar Servicio';

  // ============================================
  // Booking
  // ============================================
  static const String bookClass = 'Reservar Clase';
  static const String bookCourt = 'Reservar Cancha';
  static const String confirmBooking = 'Confirmar Reserva';
  static const String bookingSuccess = 'Reserva realizada exitosamente';
  static const String bookingFailed = 'Error al realizar la reserva';
  static const String selectSchedule = 'Seleccionar Horario';
  static const String selectCourt = 'Seleccionar Cancha';
  static const String selectProfessor = 'Seleccionar Profesor';

  // ============================================
  // Schedule
  // ============================================
  static const String createScheduleTitle = 'Crear Horario Disponible';
  static const String scheduleDate = 'Fecha';
  static const String startTime = 'Hora de Inicio';
  static const String endTime = 'Hora de Fin';
  static const String scheduleCreated = 'Horario creado exitosamente';
  static const String scheduleDeleted = 'Horario eliminado exitosamente';
  static const String scheduleConflict = 'Conflicto de horarios';
  static const String generateMultipleSlots = 'Generar múltiples horarios';

  // ============================================
  // Tenant
  // ============================================
  static const String selectTenant = 'Seleccionar Centro';
  static const String tenantSelected = 'Centro seleccionado';
  static const String tenantNotFound = 'Centro no encontrado';
  static const String joinTenant = 'Unirse al Centro';
  static const String tenantJoined = 'Te has unido al centro exitosamente';

  // ============================================
  // Empty States
  // ============================================
  static const String emptyListTitle = 'No hay elementos';
  static const String emptyListMessage =
      'No se encontraron elementos para mostrar';
  static const String emptySearchTitle = 'Sin resultados';
  static const String emptySearchMessage =
      'No se encontraron resultados para tu búsqueda';
  static const String emptyScheduleTitle = 'No hay horarios';
  static const String emptyScheduleMessage =
      'No tienes horarios disponibles en este momento';
  static const String emptyBookingTitle = 'No hay reservas';
  static const String emptyBookingMessage = 'No tienes reservas programadas';

  // ============================================
  // Success Messages
  // ============================================
  static const String savedSuccessfully = 'Guardado exitosamente';
  static const String deletedSuccessfully = 'Eliminado exitosamente';
  static const String updatedSuccessfully = 'Actualizado exitosamente';
  static const String createdSuccessfully = 'Creado exitosamente';
  static const String requestSent = 'Solicitud enviada exitosamente';
  static const String viewRequests = 'Ver Solicitudes';

  // ============================================
  // Error Messages (Generic)
  // ============================================
  static const String errorGeneric = 'Ha ocurrido un error';
  static const String errorLoading = 'Error al cargar los datos';
  static const String errorSaving = 'Error al guardar';
  static const String errorDeleting = 'Error al eliminar';
  static const String errorCreating = 'Error al crear';
  static const String errorUpdating = 'Error al actualizar';
  static const String errorSendingRequest = 'Error al enviar solicitud';

  // ============================================
  // Form Validation
  // ============================================
  static const String fieldRequired = 'Este campo es requerido';
  static const String invalidEmail = 'Email inválido';
  static const String invalidPhone = 'Teléfono inválido';
  static const String passwordsDontMatch = 'Las contraseñas no coinciden';
  static const String weakPassword = 'La contraseña es muy débil';

  // ============================================
  // Time & Date
  // ============================================
  static const String today = 'Hoy';
  static const String tomorrow = 'Mañana';
  static const String yesterday = 'Ayer';
  static const String thisWeek = 'Esta Semana';
  static const String thisMonth = 'Este Mes';
  static const String selectDate = 'Seleccionar Fecha';
  static const String selectTime = 'Seleccionar Hora';

  // ============================================
  // Service Types
  // ============================================
  static const String individualClass = 'Clase Individual';
  static const String groupClass = 'Clase Grupal';
  static const String courtRental = 'Alquiler de Cancha';
  static const String customLesson = 'Clase Personalizada';
  static const String equipmentRental = 'Alquiler de Equipos';
  static const String tournament = 'Organización de Torneo';
  static const String stringing = 'Encordado';
  static const String other = 'Otro';

  // ============================================
  // Status
  // ============================================
  static const String pending = 'Pendiente';
  static const String confirmed = 'Confirmado';
  static const String cancelled = 'Cancelado';
  static const String completed = 'Completado';

  // ============================================
  // Priority
  // ============================================
  static const String low = 'Baja';
  static const String medium = 'Media';
  static const String high = 'Alta';

  // ============================================
  // Helper Methods
  // ============================================
  /// Replaces {name} placeholder with actual name
  static String welcomeProfessorWithName(String name) {
    return welcomeProfessor.replaceAll('{name}', name);
  }
}
