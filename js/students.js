/**
 * students.js
 * Lógica de gestión de estudiantes
 */

/** Renderiza la tabla de estudiantes */
function renderStudents(students) {
  const tbody = document.getElementById('students-body');
  if (!students || students.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" class="empty-row">No hay estudiantes registrados</td></tr>';
    return;
  }
  tbody.innerHTML = students.map(s => `
    <tr>
      <td>${escapeHtml(s.cedula)}</td>
      <td>${escapeHtml(s.nombre)} ${escapeHtml(s.apellido)}</td>
      <td>${escapeHtml(s.semestre)}° Sem.</td>
      <td>${escapeHtml(s.carrera)}</td>
      <td>${escapeHtml(s.correo || '—')}</td>
      <td>${escapeHtml(s.telefono || '—')}</td>
      <td>
        <div class="action-btns">
          <button class="btn-icon" title="Editar" onclick="editStudent('${escapeHtml(s.id)}')">✏️</button>
          <button class="btn-icon" title="Eliminar" onclick="confirmDeleteStudent('${escapeHtml(s.id)}')">🗑️</button>
        </div>
      </td>
    </tr>
  `).join('');
}

/** Carga y renderiza todos los estudiantes */
function loadStudents() {
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  renderStudents(students);
}

/** Filtra estudiantes por búsqueda */
function filterStudents() {
  const query = document.getElementById('student-search').value.toLowerCase();
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS).filter(s =>
    s.cedula.toLowerCase().includes(query) ||
    s.nombre.toLowerCase().includes(query) ||
    s.apellido.toLowerCase().includes(query) ||
    s.carrera.toLowerCase().includes(query)
  );
  renderStudents(students);
}

/** Abre el formulario para editar un estudiante */
function editStudent(id) {
  const s = Storage.findById(STORAGE_KEYS.STUDENTS, id);
  if (!s) return;
  document.getElementById('student-id').value = s.id;
  document.getElementById('student-cedula').value = s.cedula;
  document.getElementById('student-nombre').value = s.nombre;
  document.getElementById('student-apellido').value = s.apellido;
  document.getElementById('student-semestre').value = s.semestre;
  document.getElementById('student-carrera').value = s.carrera;
  document.getElementById('student-correo').value = s.correo || '';
  document.getElementById('student-telefono').value = s.telefono || '';
  document.getElementById('student-fecha-nacimiento').value = s.fechaNacimiento || '';
  document.getElementById('student-direccion').value = s.direccion || '';
  document.getElementById('student-modal-title').textContent = 'Editar Estudiante';
  openModal('student-modal');
}

/** Confirma eliminación de estudiante */
function confirmDeleteStudent(id) {
  const s = Storage.findById(STORAGE_KEYS.STUDENTS, id);
  if (!s) return;
  document.getElementById('confirm-message').textContent =
    `¿Está seguro que desea eliminar al estudiante "${s.nombre} ${s.apellido}"?`;
  document.getElementById('confirm-delete-btn').onclick = () => deleteStudent(id);
  openModal('confirm-modal');
}

/** Elimina un estudiante */
function deleteStudent(id) {
  Storage.remove(STORAGE_KEYS.STUDENTS, id);
  closeModal('confirm-modal');
  loadStudents();
  updateDashboard();
  showToast('Estudiante eliminado correctamente', 'success');
}

/** Guarda (crea o actualiza) un estudiante */
function saveStudent(event) {
  event.preventDefault();
  clearStudentErrors();

  const id = document.getElementById('student-id').value;
  const cedula = document.getElementById('student-cedula').value.trim();
  const nombre = document.getElementById('student-nombre').value.trim();
  const apellido = document.getElementById('student-apellido').value.trim();
  const semestre = document.getElementById('student-semestre').value;
  const carrera = document.getElementById('student-carrera').value;
  const correo = document.getElementById('student-correo').value.trim();
  const telefono = document.getElementById('student-telefono').value.trim();
  const fechaNacimiento = document.getElementById('student-fecha-nacimiento').value;
  const direccion = document.getElementById('student-direccion').value.trim();

  let valid = true;

  if (!cedula) {
    showFieldError('err-student-cedula', 'La cédula es requerida');
    document.getElementById('student-cedula').classList.add('error');
    valid = false;
  }
  if (!nombre) {
    showFieldError('err-student-nombre', 'El nombre es requerido');
    document.getElementById('student-nombre').classList.add('error');
    valid = false;
  }
  if (!apellido) {
    showFieldError('err-student-apellido', 'El apellido es requerido');
    document.getElementById('student-apellido').classList.add('error');
    valid = false;
  }
  if (!semestre) {
    showFieldError('err-student-semestre', 'El semestre es requerido');
    document.getElementById('student-semestre').classList.add('error');
    valid = false;
  }
  if (!carrera) {
    showFieldError('err-student-carrera', 'La carrera es requerida');
    document.getElementById('student-carrera').classList.add('error');
    valid = false;
  }
  if (correo && !isValidEmail(correo)) {
    showFieldError('err-student-correo', 'El correo no es válido');
    document.getElementById('student-correo').classList.add('error');
    valid = false;
  }

  if (!valid) return;

  // Verificar cédula duplicada (excepto al editar el mismo registro)
  const existing = Storage.getAll(STORAGE_KEYS.STUDENTS).find(
    s => s.cedula.toLowerCase() === cedula.toLowerCase() && s.id !== id
  );
  if (existing) {
    showFieldError('err-student-cedula', 'Ya existe un estudiante con esta cédula');
    document.getElementById('student-cedula').classList.add('error');
    return;
  }

  const studentData = { cedula, nombre, apellido, semestre, carrera, correo, telefono, fechaNacimiento, direccion };

  if (id) {
    Storage.update(STORAGE_KEYS.STUDENTS, id, studentData);
    showToast('Estudiante actualizado correctamente', 'success');
  } else {
    Storage.add(STORAGE_KEYS.STUDENTS, studentData);
    showToast('Estudiante registrado correctamente', 'success');
  }

  closeModal('student-modal');
  loadStudents();
  updateDashboard();
}

function clearStudentErrors() {
  ['student-cedula', 'student-nombre', 'student-apellido', 'student-semestre', 'student-carrera', 'student-correo'].forEach(id => {
    document.getElementById(id).classList.remove('error');
  });
  ['err-student-cedula', 'err-student-nombre', 'err-student-apellido', 'err-student-semestre', 'err-student-carrera', 'err-student-correo'].forEach(id => {
    document.getElementById(id).textContent = '';
  });
}
