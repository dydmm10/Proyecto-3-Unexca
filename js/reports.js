/**
 * reports.js
 * Generación de reportes y exportación de datos
 */

/** Renderiza todos los reportes */
function renderReports() {
  renderCareerReport();
  renderPassFailReport();
  renderCourseAverageReport();
  renderSemesterReport();
}

/** Reporte: estudiantes por carrera */
function renderCareerReport() {
  const container = document.getElementById('report-by-career');
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);

  if (students.length === 0) {
    container.innerHTML = '<p style="color:var(--text-light);font-size:.9rem;">Sin datos disponibles</p>';
    return;
  }

  const counts = {};
  students.forEach(s => {
    counts[s.carrera] = (counts[s.carrera] || 0) + 1;
  });

  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);
  const max = sorted[0][1];

  container.innerHTML = sorted.map(([carrera, count]) => `
    <div class="report-item">
      <span class="report-label">${escapeHtml(carrera)}</span>
      <div class="report-bar-container">
        <div class="report-bar" style="width:${(count / max) * 100}%"></div>
      </div>
      <span class="report-value">${count}</span>
    </div>
  `).join('');
}

/** Reporte: aprobados vs reprobados */
function renderPassFailReport() {
  const container = document.getElementById('report-pass-fail');
  const grades = Storage.getAll(STORAGE_KEYS.GRADES);

  if (grades.length === 0) {
    container.innerHTML = '<p style="color:var(--text-light);font-size:.9rem;">Sin datos disponibles</p>';
    return;
  }

  let aprobados = 0;
  let reparacion = 0;
  let reprobados = 0;

  grades.forEach(g => {
    const n = parseFloat(g.nota);
    if (n >= 10) aprobados++;
    else if (n >= 9) reparacion++;
    else reprobados++;
  });

  const total = grades.length;
  const pAprobados = Math.round((aprobados / total) * 100);
  const pReparacion = Math.round((reparacion / total) * 100);
  const pReprobados = Math.round((reprobados / total) * 100);

  container.innerHTML = `
    <div class="report-item">
      <span class="report-label"><span class="badge badge-success">Aprobados</span></span>
      <div class="report-bar-container">
        <div class="report-bar" style="width:${pAprobados}%;background:var(--success)"></div>
      </div>
      <span class="report-value">${aprobados} (${pAprobados}%)</span>
    </div>
    <div class="report-item">
      <span class="report-label"><span class="badge badge-warning">Reparación</span></span>
      <div class="report-bar-container">
        <div class="report-bar" style="width:${pReparacion}%;background:var(--warning)"></div>
      </div>
      <span class="report-value">${reparacion} (${pReparacion}%)</span>
    </div>
    <div class="report-item">
      <span class="report-label"><span class="badge badge-danger">Reprobados</span></span>
      <div class="report-bar-container">
        <div class="report-bar" style="width:${pReprobados}%;background:var(--danger)"></div>
      </div>
      <span class="report-value">${reprobados} (${pReprobados}%)</span>
    </div>
  `;
}

/** Reporte: promedio por materia */
function renderCourseAverageReport() {
  const container = document.getElementById('report-by-course');
  const grades = Storage.getAll(STORAGE_KEYS.GRADES);
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);

  if (grades.length === 0) {
    container.innerHTML = '<p style="color:var(--text-light);font-size:.9rem;">Sin datos disponibles</p>';
    return;
  }

  const sums = {};
  const counts = {};
  grades.forEach(g => {
    sums[g.courseId] = (sums[g.courseId] || 0) + parseFloat(g.nota);
    counts[g.courseId] = (counts[g.courseId] || 0) + 1;
  });

  const courseAverages = Object.entries(sums).map(([courseId, sum]) => {
    const course = courses.find(c => c.id === courseId);
    return {
      name: course ? course.nombre : 'Desconocida',
      avg: sum / counts[courseId],
    };
  }).sort((a, b) => b.avg - a.avg);

  container.innerHTML = courseAverages.map(({ name, avg }) => `
    <div class="report-item">
      <span class="report-label">${escapeHtml(name)}</span>
      <div class="report-bar-container">
        <div class="report-bar" style="width:${(avg / 20) * 100}%"></div>
      </div>
      <span class="report-value">${avg.toFixed(1)}</span>
    </div>
  `).join('');
}

/** Reporte: estudiantes por semestre */
function renderSemesterReport() {
  const container = document.getElementById('report-by-semester');
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);

  if (students.length === 0) {
    container.innerHTML = '<p style="color:var(--text-light);font-size:.9rem;">Sin datos disponibles</p>';
    return;
  }

  const counts = {};
  students.forEach(s => {
    const sem = `${s.semestre}° Semestre`;
    counts[sem] = (counts[sem] || 0) + 1;
  });

  const sorted = Object.entries(counts).sort((a, b) => {
    const numA = parseInt(a[0]);
    const numB = parseInt(b[0]);
    return numA - numB;
  });

  const max = Math.max(...sorted.map(([, v]) => v));

  container.innerHTML = sorted.map(([sem, count]) => `
    <div class="report-item">
      <span class="report-label">${escapeHtml(sem)}</span>
      <div class="report-bar-container">
        <div class="report-bar" style="width:${(count / max) * 100}%"></div>
      </div>
      <span class="report-value">${count}</span>
    </div>
  `).join('');
}

/** Exporta estudiantes como CSV */
function exportStudentsCSV() {
  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  if (students.length === 0) {
    showToast('No hay estudiantes para exportar', 'warning');
    return;
  }

  const headers = ['Cédula', 'Nombre', 'Apellido', 'Semestre', 'Carrera', 'Correo', 'Teléfono', 'Fecha Nacimiento', 'Dirección'];
  const rows = students.map(s => [
    s.cedula, s.nombre, s.apellido, s.semestre, s.carrera,
    s.correo || '', s.telefono || '', s.fechaNacimiento || '', s.direccion || '',
  ].map(csvEscape));

  downloadCSV('estudiantes.csv', [headers, ...rows]);
  showToast('Estudiantes exportados exitosamente', 'success');
}

/** Exporta calificaciones como CSV */
function exportGradesCSV() {
  const grades = Storage.getAll(STORAGE_KEYS.GRADES);
  if (grades.length === 0) {
    showToast('No hay calificaciones para exportar', 'warning');
    return;
  }

  const students = Storage.getAll(STORAGE_KEYS.STUDENTS);
  const courses = Storage.getAll(STORAGE_KEYS.COURSES);

  const headers = ['Cédula', 'Estudiante', 'Materia', 'Código', 'Nota', 'Período', 'Tipo', 'Estado'];
  const rows = grades.map(g => {
    const student = students.find(s => s.id === g.studentId);
    const course = courses.find(c => c.id === g.courseId);
    const status = getGradeStatus(g.nota);
    return [
      student ? student.cedula : '',
      student ? `${student.nombre} ${student.apellido}` : '',
      course ? course.nombre : '',
      course ? course.codigo : '',
      g.nota,
      g.periodo,
      g.tipo || '',
      status.label,
    ].map(csvEscape);
  });

  downloadCSV('calificaciones.csv', [headers, ...rows]);
  showToast('Calificaciones exportadas exitosamente', 'success');
}

/** Convierte un valor para CSV (escapa comas, comillas y saltos de línea) */
function csvEscape(value) {
  const str = String(value ?? '');
  if (str.includes(',') || str.includes('"') || str.includes('\n') || str.includes('\r')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

/** Dispara la descarga de un CSV */
function downloadCSV(filename, rows) {
  const bom = '\uFEFF';
  const content = bom + rows.map(r => r.join(',')).join('\r\n');
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
