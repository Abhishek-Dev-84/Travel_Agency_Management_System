from django.db import models
from django.utils import timezone
from django.conf import settings
from bookings.models import Booking, Customer
from vehicles.models import Vehicle
from decimal import Decimal


class Invoice(models.Model):
    class PaymentStatus(models.TextChoices):
        UNPAID = 'Unpaid', 'Unpaid'
        PAID = 'Paid', 'Paid'
        OVERDUE = 'Overdue', 'Overdue'
        CANCELLED = 'Cancelled', 'Cancelled'

    invoice_id = models.CharField(max_length=30, unique=True, help_text="e.g. INV-2026-001")
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name='invoices')
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='invoices')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='invoices')
    issue_date = models.DateField(default=timezone.now)
    due_date = models.DateField()
    base_fare = models.DecimalField(max_digits=10, decimal_places=2)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    taxable_amount = models.DecimalField(max_digits=10, decimal_places=2)
    tax_rate = models.DecimalField(max_digits=5, decimal_places=4, default=0.0500)
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2)
    grand_total = models.DecimalField(max_digits=10, decimal_places=2)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.UNPAID)
    payment_method = models.CharField(max_length=50, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.invoice_id} - {self.customer.name} (₹{self.grand_total})"

    def save(self, *args, **kwargs):
        # Auto-generate ID if needed
        if not self.invoice_id:
            last = Invoice.objects.order_by('-id').first()
            next_num = 1 if not last else last.id + 1
            self.invoice_id = f"INV-2026-{str(next_num).zfill(3)}"

        # Enforce Rule 11 backend tax calculation
        config_tax_rate = Decimal(str(getattr(settings, 'TAX_RATE', 0.05)))
        self.tax_rate = config_tax_rate

        fare = Decimal(str(self.base_fare or 0))
        disc = Decimal(str(self.discount or 0))

        # Taxable amount = Fare - Discount
        self.taxable_amount = max(Decimal('0.00'), fare - disc)

        # Tax = Taxable amount * tax rate
        self.tax_amount = round(self.taxable_amount * self.tax_rate, 2)

        # Grand total = Taxable amount + Tax
        self.grand_total = self.taxable_amount + self.tax_amount

        super().save(*args, **kwargs)
