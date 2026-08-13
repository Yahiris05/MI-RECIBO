export const DEFAULT_DOCUMENTS = [
  {
    id: "doc-1",
    supplier: "EDEEste",
    type: "Factura",
    date: "2024-05-08",
    category: "Servicios públicos",
    amount: 1540.20,
    notes: "Pago de electricidad mensual local comercial.",
    format: "PDF"
  },
  {
    id: "doc-2",
    supplier: "Office Depot",
    type: "Factura",
    date: "2024-05-07",
    category: "Útiles de oficina",
    amount: 4920.00,
    notes: "Compra de suministros: Resmas de papel, tóner HP y carpetas.",
    format: "PDF"
  },
  {
    id: "doc-3",
    supplier: "Altice",
    type: "Factura",
    date: "2024-05-06",
    category: "Telecomunicaciones",
    amount: 2200.00,
    notes: "Servicio de internet fibra óptica y telefonía fija.",
    format: "PDF"
  },
  {
    id: "doc-4",
    supplier: "IMCA",
    type: "Comprobante",
    date: "2024-05-05",
    category: "Mantenimiento",
    amount: 8900.50,
    notes: "Mantenimiento preventivo de planta eléctrica.",
    format: "PDF"
  },
  {
    id: "doc-5",
    supplier: "Recibo de pago equipo",
    type: "Recibo",
    date: "2024-05-04",
    category: "Tecnología",
    amount: 12500.00,
    notes: "Compra de periféricos de oficina (teclados y monitores).",
    format: "PDF"
  },
  {
    id: "doc-6",
    supplier: "Factura Agua",
    type: "Factura",
    date: "2024-05-03",
    category: "Servicios públicos",
    amount: 450.00,
    notes: "Factura mensual CAASD.",
    format: "PDF"
  }
];

export const DEFAULT_REMINDERS = [
  {
    id: "rem-1",
    title: "Declaración ITBIS",
    date: "2024-05-12",
    daysLeft: 3,
    urgency: "Importante",
    status: "pending"
  },
  {
    id: "rem-2",
    title: "Renovación licencia comercial",
    date: "2024-05-19",
    daysLeft: 10,
    urgency: "Importante",
    status: "pending"
  },
  {
    id: "rem-3",
    title: "Pago Seguridad Social",
    date: "2024-05-27",
    daysLeft: 18,
    urgency: "Normal",
    status: "pending"
  },
  {
    id: "rem-4",
    title: "Renovación póliza de seguro",
    date: "2024-06-03",
    daysLeft: 25,
    urgency: "Normal",
    status: "pending"
  },
  {
    id: "rem-5",
    title: "Pago de Alquiler",
    date: "2024-06-08",
    daysLeft: 30,
    urgency: "Normal",
    status: "pending"
  }
];

export const DEFAULT_STATS = {
  docsCount: 128,
  pendingReminders: 5,
  monthlyInvoices: 18,
  categoriesCount: 7
};

export const DEFAULT_PROFILE = {
  name: "Empresa S.R.L.",
  rnc: "1-01-12345-6",
  email: "empresa@ejemplo.com",
  phone: "809-123-4567"
};
