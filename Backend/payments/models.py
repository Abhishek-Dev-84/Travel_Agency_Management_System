from django.db import models
from billing.models import Invoice
import uuid


class Payment(models.Model):
    class PaymentMethod(models.TextChoices):
        UPI = 'UPI', 'UPI (Demo)'
        CREDIT_CARD = 'CREDIT_CARD', 'Credit Card (Demo)'
        DEBIT_CARD = 'DEBIT_CARD', 'Debit Card (Demo)'
        CASH = 'CASH', 'Cash'

    class PaymentStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        PAID = 'PAID', 'Paid'
        FAILED = 'FAILED', 'Failed'
        CANCELLED = 'CANCELLED', 'Cancelled'

    payment_id = models.CharField(max_length=30, unique=True, help_text="e.g. PAY-2026-001")
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices, default=PaymentMethod.UPI)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    transaction_ref = models.CharField(max_length=60, unique=True)
    qr_payload = models.TextField(blank=True, help_text="Text representation for demo QR code")
    is_demo = models.BooleanField(default=True, help_text="Always True for TAMS simulated payments")
    paid_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.payment_id} - {self.invoice.invoice_id} ({self.payment_status})"

    def save(self, *args, **kwargs):
        if not self.payment_id:
            last = Payment.objects.order_by('-id').first()
            next_num = 1 if not last else last.id + 1
            self.payment_id = f"PAY-2026-{str(next_num).zfill(3)}"

        if not self.transaction_ref:
            short_uuid = uuid.uuid4().hex[:8].upper()
            self.transaction_ref = f"TXN-DEMO-{short_uuid}"

        if not self.qr_payload:
            self.qr_payload = (
                f"TAMS DEMO PAYMENT\n"
                f"Reference: {self.transaction_ref}\n"
                f"Invoice: {self.invoice.invoice_id}\n"
                f"Amount: ₹{self.amount}\n"
                f"Status: SIMULATED DEMO ONLY"
            )
        super().save(*args, **kwargs)
